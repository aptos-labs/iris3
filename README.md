# Iris3

Iris3 automatically assigns labels to Google Cloud Platform resources for manageability and easier billing reporting.
Each supported resource in the GCP Organization will get automatically-generated labels with keys like iris_zone (the prefix is configurable), and the copied value. For example, a Google Compute Engine instance would get labels like [iris_name:nginx], [iris_region:us-central1] and [iris_zone:us-central1-a].

# Runbook

See
the [runbook for Iris3](https://www.notion.so/aptoslabs/Iris3-GCP-Labeler-Deployment-50544effe3844dffadfc07219bfe9a7b)
.

## When it does it

Iris adds labels:

* On resource creation, by listening to Google Cloud Operations (Stackdriver) Logs.
    - You can disable this, see ["Deploy"](#deployment).
* On schedule, using a Cloud Scheduler cron job that the deployer sets up for you.
    - By default, only some types of resources are labeled on Cloud Scheduler runs.
    - This can be configured so that all resources are labeled. See `label_all_on_cron` below.

## Labeling existing resources

* When you first use Iris, you may want to label all existing resources.
* To do this, deploy it with `label_all_on_cron: True` and wait for the next scheduled run, or manually trigger a run.
* You may want to then redeploy Iris with `label_all_on_cron: False` to avoid the daily resource consumption.


### Deployment

* Get the code with `git clone https://github.com/aptos-labs/iris3`
* Have Python 3.11+ as your default `python3`.
* Install tools `envsubst` and `jq`.
* Install and initialize `gcloud` using an account with the [above-mentioned](#before-deploying) roles.
* Config
  * Optionally configure by editing the configuration files ([See more documentation below](#configuration).)
* Run `./deploy.sh <PROJECT_ID> `.
    * The above is the default. There are also command-line options, to be put  at the end of the command line after the project id. Run `deploy.sh -h` for documentation.