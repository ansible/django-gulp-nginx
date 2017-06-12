[![Build Status](https://travis-ci.org/ansible/django-gulp-nginx.svg?branch=master)](https://travis-ci.org/ansible/django-gulp-nginx)

# django-gulp-nginx

A framework for building containerized [django](https://www.djangoproject.com/) applications. Utilizes [Ansible Container](https://github.com/ansible/ansible-container) to manage each phase of the application lifecycle, and enables you to begin developing immediately with containers.

Includes *django*, *gulp*, *nginx*, and *postgresql* services, pre-configured to work together, and ready for development. You can easily adjust the settings of each, as well as drop in new services directly from [Ansible Galaxy](https://galaxy.ansible.com). The following topics will help you get started:  

- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Developing](#developing)
- [Adding Service](#adding)
- [Testing](#testing)
- [Deploying](#openshift)
- [Contributing](#contributing)
- [Dependencies](#dependencies)
- [License](#license)
- [Authors](#author)

<h2 id="requirements">Requirements</h2>

Before starting, you'll need to have the following:

- Ansible Container, running from source. See the [Running from source guide](http://docs.ansible.com/ansible-container/installation.html#running-from-source), for assistance. Be sure to install *docker* engine support, and if you intend to run the deployment example, install *openshift* engine support. 
- [Docker Engine](https://www.docker.com/products/docker-engine) or [Docker for Mac](https://docs.docker.com/engine/installation/mac/)
- make
- git

<h2 id="getting-started">Getting Started</h2>

To start creating your Django application, create a new directory, and initialize it with a copy of this project:  

```
# Create a new directory for your project
$ mkdir demo

# Set the working directory
$ cd demo 

# Initialize the project
$ ansible-container init ansible.django-gulp-nginx
```

Next, build a local copy of the project's images. From the new project directory, start the build process by running the following: 

```bash
# Create the container images
$ ansible-container build
```

The build process will take a few minutes to complete. It will take longer the first time you run it, because it needs to pull the base image, and build the Conductor image.

After the Conductor build completes, each service in the [container.yml](./container.yml) file will be built. Services are built by executing one or more Ansible roles, and as the build process progresses, task names will scroll across your session window as each role executes.

Once completed, you'll have a local copy of the built images that can be used to run the application. When you're ready to start the application, run the following:

```bash
# Start the containers
$ ansible-container run
```
 
Requests are proxied through the *gulp* service. Before you can view the sample web page, the gulp web server needs to be started. This may take a couple moments, as the process first install node modules and bower components prior to starting the service. You can watch the logs by running the following:

```bash
# Watch the logs for gulp service
$ docker logs -f demo_gulp_1
```

The following message in the logs indicates the service is running:

```
[17:05:29] Starting 'js'...
[BS] Access URLs:
 -----------------------------------
       Local: http://localhost:8080
    External: http://172.21.0.4:8080
 -----------------------------------
          UI: http://localhost:3001
 UI External: http://172.21.0.4:3001
 -----------------------------------
[BS] Serving files from: dist
[17:05:30] Finished 'lib' after 601 ms
[17:05:30] Finished 'html' after 574 ms
[17:05:30] Finished 'sass' after 644 ms
[17:05:30] Finished 'templates' after 685 ms
[17:05:30] Finished 'js' after 631 ms
```

To view the sample app, open a browser and go to [http://localhost:8080](http://localhost:8080), where you'll see a simple "Hello World!" message.

<h2 id="developing">Developing</h2>
 
When you start the containers with `ansible-container run`, they start in development mode, which means that the *dev_overrides* section of each service definition in [container.yml](./container.yml) takes precedence, causing the *gulp*, *django* and *postgresql* services to start, and the *nginx* service to stop.  

The frontend code can be found in the [src](./src) directory, and the backend django code is found in the [project](./project) directory. You can begin making changes right away, and as you do, you'll see the results reflected in your browser almost immediately.

Here's a brief overview of each of the running services:

### gulp 

While developing, the *gulp* service will actively watch for changes to files in the [src](./src) directory tree, where custom frontend components (i.e. html, javascript, css, etc.) live. As new files are created, or existing files modified, the *gulp* service will compile the updates, place results in the [dist](./dist) directory, and using [browsersync](https://browsersync.io/), refresh your browser.

In addition to compiling the frontend components, the *gulp* service will proxy requests beginning with */static* or */admin* to the *django* service. The proxy settings are configurable in *gulpfile.js*, so as you add additional routes to the django service, you can expand the number of paths forwarded by the *gulp* service. 

**NOTE**
> *As you add new routes to the backend, be sure to update the nginx service definition by modifying [container.yml](./container.yml), and adjusting the parameters passed to the ansible.nginx-container role. Specifically, you'll need to update the PROXY_LOCATION value.*

### django

The *django* service provides the backend of the application. During development the *runserver* process executes, and accepts requests from the *gulp* service. The source code to the Django app lives in the [project](./project) directory tree. To add additional Python and Django modules, add the module names and versions to [requirements.txt](./requirements.txt), and run the `ansible-container build` command to install and incorporate them into the *django* image.

When the *django* container starts, it waits for the PostgreSQL database to be ready, and then it performs migrations, all before starting the server process. Use `make django_manage makemigrations` and `make django_manage migrate` to create and run migrations during development.  

### postgresql

The *postgresql* service provides the *django* service with access to a database, and by default stores the database on the *postgres-data* volume. Modify [container.ym](./container.yml) to set the database name, and credentials.  

<h2 id="adding">Adding Services</h2>

You can add preconfigured services to the application by installing *Container Enabled* roles directly from the [Galaxy web site](https://galaxy.ansible.com). Look for roles on the site by going to the [Browse Roles](https://galaxy.ansible.com/list#/roles?page=1&page_size=10&role_type=CON) page, setting the filter to *Role Type*, and choosing *Containr Enabled*. 

For example, if you want to install a Redis service, you can install the `j00bar.redis-container` role by running the following:

```
# Set the working directory to your project root
$ cd demo

# Install the role
$ ansible-container install j00bar.redis-container
```

After the install completes, the new service will be included in [container.yml](./container.yml). You'll then need to run the `build` process to update the project's images:

```bash
# Rebuild the project images
$ ansible-container build 
```

After the build process completes, restart the application by running the following:

```bash
# Run the application 
$ ansible-container restart
```

<h2 id="testing">Testing</h2>

After you've made changes to the app, and you're ready to test, you'll first run `ansible-container build` to create a new set of images containing the latest code. During the build process, the [project](./project) directory, which contains your custom Django files, will be copied into the *django* image at */django*, and your frontend assets, contained in [src](./src), will be compiled and copied to the [dist](./dist) directory, and then copied into the *nginx* image at */static*.

Once the new images are built, run the following to test the images:

```bash
# Restart the application in production mode for testing
$ ansible-container stop
$ ansible-container run --production
```

The above starts the containers in production mode, ignoring the *dev_overrides* section of each service definition in [container.yml](./container.yml)`, and executing the containers as if they were deployed to production. This time the *django*, *nginx*, and *postgresql* containers starts, and the *gulp* container stops. Just as before, access the application at [http://localhost:8080](http://localhost:8080).

### django

In production this service will run the *gunicorn* process to accept requests from the *nginx* service. Just as before, when the service starts it will wait for the PostgreSQL database to become available, and then perform migrations, before starting the server process. 

### nginx 

This service will respond to requests for frontend assets, and proxy requests to *django* service endpoints. Before running `ansible-container build`, if you added new routes to your django application, be sure to update the nginx configuration by modifying [container.yml](./container.yml), and adjusting the PROXY_LOCATION parameter passed to the *ansible.nginx-container* role. This will impact the *nginx.conf* file that gets added to the image.

### postgresql

Just as before, the *postgresql* sevice provides the *django* service with access to a database, and by default stores the database on the *postgres-data* volume.

NOTE
> *If you start the image build process by running `make build`, the postgres-data volume will be deleted, and the application will start with an empty database.*

<h2 id="openshift">Deploying</h2>

Ansible Container can deploy to Kubernetes and OpenShift. For the purposes of demonstrating the deployment workflow, we'll use OpenShift. If you want to carry out the actual steps, you'll need access to an OpenShift instance. The [Install and Configure Openshift](http://docs.ansible.com/ansible-container/configure_openshift.html) guide at our doc site provides a how-to that will help you create a containerized instance.

Log into the cluster using your *developer* account:


```bash
# Log into the local cluster
$ oc login -u developer
```

Create a *demo* project:

```bash
# Create a new project
$ oc new-project demo
```

The project name is defined in [container.yml](./container.yml). Within the *settings* section, you will find a *k8s_namespace* section that sets the name. The project name is arbitrary. However, before running the `deploy` command, the project must already exist, and the user you're logged in as, must have access to it. 
 
Next, use the `deploy` command to push the project images to the local registry, and create the deployment playbook. For demonstration purposes, we're referencing the *local_openshift* registry defined in [container.yml](./container.yml). Depending on how you created the local OpenShift cluster, you may need to adjust the registry attributes.

One of the registry attributes is *namespace*. For OpenShift and K8s, the registry *namespace* should match the *name* value set in *k8s_namespace* within the *settings* section. In the case of OpenShift, the *name* in *k8s_namespace* will be the *project* name, and for K8s, it's the *Namespace*. 

Once you're ready to push the images, run the following from the root of the *demo* project directory:

```bash
# Push the built images and generate the deployment playbook
$ ansible-container --engine openshift deploy --push-to local_openshift --username developer --password $(oc whoami -t)
```

The above will authenticate to the registry using the `developer` username, and a token generated by the `oc whoami -t` command. This presumes that your cluster has a `developer` account, and that you previously authenticated to the cluster with this account.

After pushing the images, a playbook is generated and written to the `ansible-deployment` directory. The name of the playbook will match the project name, and have a `.yml` extension. In this case, the name of the playbook will be `demo.yml`.

You will also find a `roles` directory containing the `ansible.kubernetes-modules` role. The deployment playbook relies on this role for access to the Ansible Kubernetes modules.

To deploy the application, execute the playbook, making sure to include the appropriate tag. Possible tags include: `start`, `stop`, `restart`, and `destroy`. To start the application, run the following:

```bash
# Run the deployment playbook
$ ansible-playbook ./ansible-deployment/demo.yml --tags start
```
Once the playbook completes, log into the OpenShift console to check the status of the deployment. From the *Applications* menu, choose *Routes*, and find the URL that points to the *nginx* service. Using this URL, you can access the appication running on the cluster.


<h2 id="contributing">Contributing</h2>

If you work with this project and find issues, please [submit an issue](https://github.com/ansible/django-gulp-nginx/issues). 

Pull requests are welcome. If you want to help add features and maintain the project, please feel free to jump in, and we'll review your request quickly, and help you get it merged.

<h2 id="dependencies">Dependencies</h2>

This project depends on the following [Galaxy](https://galaxy.ansible.com) roles:

- [ansible.nginx-container](https://galaxy.ansible.com/ansible/nginx-container)

<h2 id="license">License</h2>

[Apache v2](https://www.apache.org/licenses/LICENSE-2.0)

<h2 id="author">Authors</h2>

View [AUTHORS](./AUTHORS) for a list contributors. Thanks everyone!



