[![Build Status](https://travis-ci.org/ansible/django-gulp-nginx.svg?branch=master)](https://travis-ci.org/ansible/django-gulp-nginx)

# django-gulp-nginx

A framework for building containerized [django](https://www.djangoproject.com/) applications. Utilizes [Ansible Container](https://github.com/ansible/ansible-container) to manage each phase of the application lifecycle, allowing you to begin developing immediately with containers.

Includes django, gulp, nginx, and postgresql services, pre-configured to work together, and ready for development. You can easily adjsut the settings of each, as well as drop in new services directly from [Ansible Galaxy](https://galaxy.ansible.com). The following topics will help you get started:  

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

- Ansible Container, running from source. See the [Running from source guide](http://docs.ansible.com/ansible-container/installation.html#running-from-source), for assistance. 
- [Docker Engine](https://www.docker.com/products/docker-engine) or [Docker for Mac](https://docs.docker.com/engine/installation/mac/)
- make
- git

<h2 id="getting-started">Getting Started</h2>

To start creating your Django application, create a new directory and initialize it with a copy of this project:  

```
# Create a new directory for your project
$ mkdir demo

# Set the working directory
$ cd demo 

# Initialize the project
$ ansible-container init ansible.django-gulp-nginx
```

Next, build a local copy of the project's images. From the new project directory, start the build process by running the following: 

```
# Create the container images
$ ansible-container build
```

The build process will take a few minutes to complete, taking longer the first time you run it. As it executes, task names will scroll across your session window marking its progression through the Ansible playbook, [main.yml](./blob/master/ansible/main.yml). 

Once completed, you'll have a local copy of the images, which you can use to create containers and run the application. When you're ready to start the application, run the following:

```
# Start the containers
$ ansible-container run
```

The project's containers are now running, ready for building your new app. To view the app, open a browser and go to [http://localhost:8080](http://localhost:8080), where you'll see a simple "Hello World!" message.

<h2 id="developing">Developing</h2>
 
When you start the containers by running `ansible-container run`, they start in development mode, which means that the *dev_overrides* section of each service definition in [ansbile/container.yml](./ansible/container.yml) takes precedence, causing the gulp, django and postgresql services to start, and the nginx service to stop.  

The frontend code can be found in the [src](./src) directory, and the backend django code is found in the [project](./project) directory. You can begin macking changes right away, and as you do, you'll see the results reflected in your browser almost immediately.

Here's a brief overview of each of the running services:

### gulp 

While developing, the gulp container will be running, and actively watching for changes to files in the [src](./src) directory tree, where custom frontend components (i.e. html, javascript, css, etc.) live. As new files are created or existing files modified, the gulp service will compile the updates, place results in the [dist](./dist) directory, and using [browsersync](https://browsersync.io/), refresh your browser.

In addition to compiling the frontend components, the gulp service will proxy requests beginning with */static* or */admin* to the django service. The proxy settings are configurable in *gulpfile.js*, so as you add additional routes to the django service, you can expand the number of paths forwarded by the gulp service. 

NOTE
> *As you add new routes to the backend, be sure to update the nginx configuration by modifying [ansible/main.yml](./ansible/main.yml), and adjusting the parameters passed to the chouseknecht.nginx-container-1 role. Specifically, you'll need to update the PROXY_LOCATION value.*

### django

The django service provides the backend of the application. During development the *runserver* process executes, and accepts requests from the gulp service. The source code to the django app lives in the [project](./project) directory tree. To add additional python and django modules,add the module names and versions to [requirements.txt](./requirements.txt), and run the `ansible-container build` command to install and incorporate them into the django image.

When the django container starts, it waits for the postgresql database to be ready, and then it performs migrations, all before starting the server process. Use `make django_manage makemigrations` and `make django_manage migrate` to create and run migrations during develoopment.  

### postgresql

The posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume. Modify [ansible/container.ym](./ansible/container.yml) to set the database name, and credentials.  

<h2 id="adding">Adding Services</h2>

You can add preconfigured services to the application by installing *Container Enabled* roles directly from the [Galaxy web site](https://galaxy.ansible.com). Look for roles on the site by going to the [Browse Roles](https://galaxy.ansible.com/list#/roles?page=1&page_size=10&role_type=CON) page, setting the filter to *Role Type*, and choosing *Containr Enabled*. 

For example, if you want to install a Redis service, you can install the `j00bar.redis-container` role by running the following:

```
# Set the working directory to your project root
$ cd demo

# Install the role
$ ansible-container install j00bar.redis-container
```

After the install completes the new service will be included in [ansible/container.yml](./ansible/container.yml) and [ansible/main.yml](./ansible/main.yml), and you can edit the files directly to adjust the configuration. 

Start the build process to update the project's images by running the following:

```
# Rebuild the project images
$ ansible-container build 
```

After the build process completes, restart the application by running the following:

```
# Run the application 
$ ansible-container run 
```

<h2 id="testing">Testing</h2>

After you've made changes to the app, and you're ready to test, you'll first run `ansible-container build` to create a new set of images containing the latest code. During the build process, the [project](./project) directory, which containins your custom django files, will be copied into the django image at */django*, and your frontend assets, contained in [src](./src), will be compiled and copied to the [dist](./dist) directory, and then copied into the nginx image at */static*.

Once the new images are built, run the command `ansible-container run --production` to test the images. This will start containers in production mode, ignoring the *dev_overrides * section of each service definition in `container.yml`, and executing the containers as if they were deployed to production. You'll see the django, nginx and postgresql containers start, and the gulp container stop.

### django

In production this service will run the gunicorn process to accept requests from the nginx service. Just as before, when the service starts it will wait for the postgresql database to become available, and then perform migrations, before starting the server process. 

### nginx 

This service will respond to requests for frontend assets, and proxy requests to django service endpoints. Before running `ansible-container build`, if you added new routes to your django application, be sure to update the nginx configuration by modifying [ansible/main.yml](./ansible/main.yml), and adjusting the PROXY_LOCATION parameter passed to the ansible.nginx-container role. This will impact the *nginx.conf* file that gets added to the image.

### postgresql

Just as before, the posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume.

NOTE
> *If you start the image build process by running `make build`, the postgres-data volume will be deleted, and the applciation will start with an empty database.*

<h2 id="openshift">Deploying</h2>

Ansible Container can deploy to Kubernetes and OpenShift. For the purposes of demonstrating the deployment workflow, we'll use OpenShift. If you want to carry out the actual steps, you'll need access to an OpenShift instance. The [Install and Configure Openshift](http://docs.ansible.com/ansible-container/configure_openshift.html) guide at our doc site provides a how-to that will help you create a containerized instance.

Using the `oc` command, create a project that matches the root directory name of your project:

```
# Create a new project
oc new-project demo
```

You can then push the project images to the OpenShift registry. If you followed the guide, and created a local instance, then the following command will push the images to the local registry:

```
# Set the working directory to the project root
$ cd demo 

# Push the images to the local OpenShift registry
$ ansible-container push --push-to https://local.openshift/demo --username developer --password $(oc whoami -t)
```

With the images in the local registry, you can generate the deployment playbook and role by running the following:

```
# Generate the deployment artifacts
$ ansible-container shipit openshift --pull-from https://local.openshift/demo
```

The deployment playbook gets created in the *ansible* directory. Use the following commands to create an inventory file, and execute the playbook:

```
# Set the working directory to ansible
$ cd ansible

# Create an inventory file containing a single entry
$ echo "localhost">inventory

# Run the playbook
$ ansible-playbook -i inventory shipit-openshift.yml
```

Once the playbook completes, log into your OpenShift console to check the status of the deployment. From the application menu, choose *Routes* to find the hostname that points to your nginx service. 


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



