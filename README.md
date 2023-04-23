# Jenkins Configuration as Code
## Introduction
This tutorial aims to help the beginners automate Jenkins deployment and configuration with Docker and Jenkins Configuration as Code approach.

## Requirements
* GitHub account. It also can be an account in GitLab, BitBucket or any other Git repository.
* Google Cloud Platform (GCP) account. Any other Cloud Platform can be used, but this tutorial does not provide examples for them yet.
* An IDE or at least a text editor.
* Docker Engine running locally on your computer.

## Agenda
* Getting started with Jenkins Server
* Moving Jenkins Server to Cloud
* Using Jenkins Configuration as Code
* Portability, Scalability and other tips

## Getting started with Jenkins Server
### Step 1 - Running containerized Jenkins
Run `vanilla` Jenkins image by using `docker run` command:
```
docker run --name jenkins --rm -p 8080:8080 jenkins/jenkins:latest
```

The following output indicates that Jenkins is up and running:
```
2023-04-22 19:14:30.632+0000 [id=22]	INFO	hudson.lifecycle.Lifecycle#onReady: Jenkins is fully up and running
```
Now, use your browser to navigate to `http://server_ip:8080`, http://127.0.0.1:8080 if Jenkins is running on your local machine.

### Step 2 - Disabling the Setup Wizard
Create `Dockerfile` and copy the following content into it (Jenkins version can be different for you):
```
FROM jenkins/jenkins:2.401
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
```

Build custom Docker image:
```
docker build -t jenkins:jcasc .
```

Run Docker container using that custom image:
```
docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
```

Navigate to `http://server_ip:8080` (http://127.0.0.1:8080) in your web browser. You should be able to see Jenkins dashboard without going through the Setup Wizard.

### Step 3 - Installing Jenkins plugins
By default no plugins are installed. You can see that by navigating to http://127.0.0.1:8080/pluginManager/installed .
In this step, we're going to pre-install a selection of Jenkins plugins.

Create a folder named `jcasc` and open a new file named `plugins.txt` in it:
```
mkdir jcasc
vim jcasc/plugins.txt
```

Then, add the following newline-separated entries into that file, using the `<plugin_id>:<version>` format:
```
ant:latest
antisamy-markup-formatter:latest
build-timeout:latest
cloudbees-folder:latest
credentials-binding:latest
email-ext:latest
git:latest
github-branch-source:latest
gradle:latest
ldap:latest
mailer:latest
matrix-auth:latest
pam-auth:latest
timestamper:latest
ws-cleanup:latest
```

Next, edit the `Dockerfile`:
```
vim Dockerfile
```

In it, add `COPY` instaruction to copy the `jcasc/plugins.txt` file into the `/usr/share/jenkins/ref/` inside the Jenkins image. Also, add `RUN` instruction, which will execute the `/usr/local/bin/install-plugins.sh` script inside the image:
```
FROM jenkins/jenkins:2.401
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY jcasc/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
```

Save the `Dockerfile` and build a new image:
```
docker build -t jenkins:jcasc .
```

Once the build is done, run the new Jenkins image:
```
docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
```

## Moving Jenkins Server to Cloud
In this section, we will go through the deployment of our Jenkins Servers in the Cloud ([Google Cloud Platform](https://cloud.google.com/) in this case), which will make the service available for our Team, regardless of where in the world any of our teammates is currently located.


### Step 1 - Creating a GCP project
Assuming that we already have a `GCP account`, first thing that needs to be done is creating a `GCP project`, where all requried GCP infrastructure resources will be deployed. We will use [Terraform](https://www.terraform.io/) to automatically create the project, and destroy it when it is not needed anymore.

Authenticate your GCP account using `gcloud` command (use your own email address associated with your GCP account):
```
gcloud auth login user@example.com
```
or
```
gcloud auth login user@example.com --no-launch-browser
```
More details can be found [here](https://cloud.google.com/sdk/gcloud/reference/auth).

Go to the `terraform/modules/project` and run the following commands on by one:
```
terraform init
```

```
terraform plan
```

```
terraform apply
```
That will create a dedicated GCP project to host required GCP infrastructure resources


Now, go to the `terraform/modules/services` folder and do the same `terraform init/plan/apply` sequence again. That will enable the following GCP APIs (there can be more in the future):
```
Google Container Registry API - containerregistry.googleapis.com
Compute Engine API - compute.googleapis.com
```

### Step 2 - Pushing Jenkins custom image to Google Container Registry
Fist, make sure that you have access to the `gcr.io` Container Registry:
```
gcloud container images list
```

You should see the following output:
```
Listed 0 items.
Only listing images in gcr.io/jcas-lab-01. Use --repository to list images in other repositories.
```
The name of the project, `jcas-lab-01` will be different for you.

Tag your local custom Jenkins image as follows:
```
docker tag jenkins:jcasc gcr.io/jcas-lab-004/jenkins:jcasc
```

Push your local custom Jenkins image to `gcr.io/jcas-lab-004/` container registry:
```
docker push gcr.io/jcas-lab-004/jenkins:jcasc
```

The output of the `gcloud container images list` command should be the following:
```
NAME
gcr.io/jcas-lab-004/jenkins
Only listing images in gcr.io/jcas-lab-004. Use --repository to list images in other repositories.
```