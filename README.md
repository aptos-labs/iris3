# Iris3

In Greek mythology, Iris (/ˈaɪrɪs/; Greek: Ἶρις) is the personification of the rainbow and messenger of the gods. She
was the handmaiden to Hera.

# Blog post

See
the [post that presents Iris](https://blog.doit-intl.com/iris-3-automatic-labeling-for-cost-control-7451b480ee13?source=friends_link&sk=b934039e5dc35c9d5e377b6a15fb6381)
.

## What it does for you

Iris automatically assigns labels to Google Cloud Platform resources for manageability and easier billing reporting.

Each supported resource in the GCP Organization will get automatically-generated labels with keys like `iris_zone` (the
prefix is configurable), and the copied value. 
For example, a Google Compute Engine instance would get labels like
`[iris_name:nginx]`, `[iris_region:us-central1]` and `[iris_zone:us-central1-a]`.

Limitation: Iris cannot *add* information, only *copy* information. For example, it can label a VM instance with its
zone, since this information is known; but it cannot add a "business unit" label because it does not know what business
unit a resource should be attributed to. For that, you should label all resources when creating them, e.g. in your
Terraform scripts.

Iris is open-source: Feel free to add functionality and add new types of labels. See the `TODO.md` file for features and
fixes you might do.

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

* Get the code with `git clone https://github.com/doitintl/iris3.git`
* Have Python 3.9+ as your default `python3`.
* Install tools `envsubst` and `jq`.
* Install and initialize `gcloud` using an account with the [above-mentioned](#before-deploying) roles.
* Config
  * Copy `config.yaml.original` to `config.yaml`.
  * Optionally configure by editing the configuration files ([See more documentation below](#configuration).)
* Run `./deploy.sh <PROJECT_ID> `.
    * The above is the default. There are also command-line options, to be put  at the end of the command line after the project id. Run `deploy.sh -h` for documentation.
* When you redeploy different versions of Iris code on top of old ones:
    * If new plugins were added or some removed, the log sink *will* be updated to reflect this.
    * If the parameters for subscriptions or topics were changed in a new version of the Iris code, the subscriptions or  topics will *not* be updated. You would have to delete them first.
* If you are changing to or from  Cloud-Scheduler-only with or without `-c`, be sure to run both org and project deployments.         
*  See `deploy.sh` for configuring Iris to add labels only with  Cloud Scheduler and not on-creation, or without the Scheduler at all, or with both Scheduler and on-creation. The latter is the default.