package validate

import (
	"fmt"
	"os"
	"time"

	"github.com/GannettDigital/paas-api-ci/goPipeline"
	"github.com/Sirupsen/logrus"
	"github.com/markbates/refresh/cmd"
	"github.com/spf13/cobra"
)

var log *logrus.Logger
var goldie goldenLog

type goldenLog struct {
	branchName string
}

func init() {
	log = logrus.New()
	goldie = goldenLog{}
}

func initRootPersistentFlags() {
	requiredCommonFlags = []string{
		"branch-name",
	}

	// required
	RootCmd.PersistentFlags().StringVar(&goldie.branchName, "branch-name", "", "Branch name, like `master` or `PAAS-1234")
}

var RootCmd = &cobra.Command{
	Use:   "goldenlog",
	Short: "Framework that supports the paas-api ci pipeline.",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		os.Setenv("AWS_ACCESS_KEY_ID", AwsAccessKey)
		os.Setenv("AWS_SECRET_ACCESS_KEY", AwsSecretAccessKey)

		if err := validatePersistantFlags(rootCmdV, requiredCommonFlags); err != nil {
			os.Exit(1)
		}
		// load configuration from s3
		configs = goPipeline.LoadConfigs(configClient)

		// Configure NR
		nr = utilsNewRelic.Configure(configs.NewRelicMonitoring, configs.AppName, configs.Environment, configs.ScalrFarmName)
		if err := nr.WaitForConnection(5 * time.Second); nil != err {
			log.WithFields(logrus.Fields{
				"err": err,
			}).Info("Connection error")
		}
		txn = nr.StartTransaction(configs.AppName, nil, nil)
		transactionInfo.Txn = txn
		transactionInfo.App = nr

		// defaults - no flag to set these
		repo.RunOptions.GoPath = os.Getenv("GOPATH")
		repo.Tagging.APIURL = "https://paas-api-tagging.gannettdigital.com/v1"

	},
	PersistentPostRun: func(cmd *cobra.Command, args []string) {
		nr.Shutdown(10 * time.Second)
		txn.End()
	},
}

func main() {
	if _, err := os.Stat("CHANGELOG.md"); os.IsNotExist(err) {
		log.WithFields(logrus.Fields{
			"error": err.Error(),
		}).Error("Could not find CHANGELOG.md")
		os.Exit(1)
	}
}

func main() {
	if err := cmd.RootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
