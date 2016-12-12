# django-gulp-nginx

A framework for building containerized [django](https://www.djangoproject.com/) applications. Utilizes [Ansible Container](https://github.com/ansible/ansible-container) to manage each phase of the application lifecycle, and enables you to begin developing immediately in containers. 

- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Developing](#developing)
- [Testing](#testing)
- [Deploying](#openshift)
- [Contributing](#contributing)
- [License](#license)
- [Dependencies](#dependencies)
- [Author](#author)

<h2 id="requirements">Requirements</h2>

- Ansible Container, running from source. See the [Running from source guide](http://docs.ansible.com/ansible-container/installation.html#running-from-source), for assistance. 
- [Docker Engine](https://www.docker.com/products/docker-engine) or [Docker for Mac](https://docs.docker.com/engine/installation/mac/)
- make
- git

<h2 id="getting-started">Getting Started</h2>

To start developing, it's as easy as...

```
# Clone this project into a local directory.
$ git clone https://github.com/chouseknecht/django-gulp-nginx.git demo

# Set the working directory to the project root
$ cd demo 

# Create the container images
$ ansible-container build
```

The build process takes a few minutes, the first time, and as it runs, build tasks will appear on your terminal session as the Ansible playbook executes. Once completetd, you'll have a local set of images for your project.

Next, start the containers: 

```
# Start the containers
$ ansible-container run
```

You now have have 3 containers running in development mode, ready for you to begin building your app. To view your app, open a browser and go to [http://localhost:8080](http://localhost:8080), and to log into the django admin site by go to [http://localhost:8080/admin](http://localhost:8080/admin)

<h2 id="developing">Developing</h2>
 
When you start the containers by running `ansible-container run`, they start in development mode, which means that the *dev_overrides* section of each service definition in [container.yml](./ansible/container.yml) takes precedence, causing the gulp, django and postgresql containers to run, and the nginx to stop.  

The frontend code can be found in the *src* directory, and the backend django code is found in the *project* directory. You can begin macking changes right away, and you will see the results reflected in your browser almost immediately.

Here's a breif overview of each of the running services:

### gulp 

While developing, the gulp container will be running, and actively watching for changes to files in the *src* directory tree. The *src* directory is where custom frontend components (i.e. html, javascript, css, etc.) live, and as new files are created or existing files modified, the gulp service will compile the updates, place results in the *dist* directory, and trigger a refresh in your browser.

In addition to compiling the frontend components, the gulp server will proxy requests beginning with */static* or */admin* to the backend service, django. The proxy settings are configurable in *gulpfile.js*, so as you add additional routes the django service, you can expand the request paths forward by the gulp service. 

As you add new routes to the backend, be sure to update the nginx configuration by modifying ansible/main.yml, and adjusting the parameters passed to the chouseknecht.nginx-container-1 role. Specifically, you'll need to update the PROXY_LOCATION value.

### django

The django service provides the backend to the application. During development the *runserver* process executes, and accepts requests from the gulp service. The source code to the django app lives in the *project* directory tree. To add additional python and django modules,add the module names and versions to *requirements.txt*, and run the `ansible-container build` command to add them to the django image.

When the django container starts, it waits for the postgresql database to be ready, and then it performs migrations, before starting the server process. Use `make django_command makemigrations` and `make django_command migrations` to create and run migrations during develoopment.  

### postgresql

The posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume. 

<h2 id="testing">Testing</h2>

After you've made changes to the app, and you're ready to test, you'll first run `ansible-container build` to add your changes to the project images, and then you'll run the containers using `ansible-container run --production`. This will start the containers in production mode, ignoring the *dev_overrides * section of each service definition, and running the containers as if they were deployed to prodction. 
In production mode the django, nginx, and postgresql containers will run, and the gulp container will stop.  

### django

The django service provides the backend for the application, but now it's running the gunicorn process to accept requests from the nginx service. Just as before, when the service starts it will wait for the postgresql database to become available, and then perform migrations, before starting the server process. 

### nginx 

The nginx service serves the frontend components, and proxies requests to the django service. If you added new routes to your django application, before running `ansible-container build`, be sure to update the nginx configuration by modifying ansible/main.yml, and adjusting the parameters passed to the chouseknecht.nginx-container-1 role. Specifically, you'll need to update the PROXY_LOCATION value.

### postgresql

The posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume.

<h2 id="openshift">Deploying</h2>

For this example we'll run a local OpenShift instance. You'll need the following to create the instance: 

- Download the [oc client](https://github.com/openshift/origin/releases/tag/v1.3.0), and add the binary to your PATH.

- If you're running Docker Engine, configure the daemon with an insecure registry parameter of 172.30.0.0/16  

    - In RHEL and Fedora, edit the /etc/sysconfig/docker file and add or uncomment the following line

        ```
        INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'
        ```
    - After editing the config, restart the Docker daemon. 

        ```
        $ sudo systemctl restart docker
        ```
- If you're using Docker Machine, you'll need to create a new instance. The following creates a new instance named *devel*

    ```
    docker-machine create -d virtualbox --engine-insecure-registry 172.30.0.0/16 --virtualbox-host-dns-resolver devel
    ```

Launch the instance:

```
$ oc cluster up
```

After the command completes, access instructions will be displayed that include the console URL along with a user account and an admin account details. For example:

```
-- Server Information ...
   OpenShift server started.
   The server is accessible via web console at:
       https://192.168.99.106:8443

   You are logged in as:
       User:     developer
       Password: developer

   To login as administrator:
       oc login -u system:admin
```

Login using the administrator account, and create a project that matches the name of your project. For example, the following creates a *symfony-mariadb-nginx* project:

```
# Login as the admin user
$ oc login https://<your Docker Host IP>:8443 -u system:admin

# Create a project with a name matching the name of our project directory
$ oc new-project symfony-mariadb-nginx
```

### Build the images

We neeed to buid a set of images for our project with the latest code deployed inside the *nginx* image. Each time you make code changes and want to deploy, you will need to run a build in order to upate the nginx image. Run the following to build the images:

```
# Set the working directory to the root of the project
$ cd symfony-mariadb-nginx

# Build the images
$ make build
```

### Push the images to the registry

For example purposes we'll push the images to Docker Hub. If you have a private registry, you could use that as well. See [registry overview](https://docs.openshift.org/latest/install_config/registry/index.html) for instructions on using registries with OpenShit. 

To push the images we'll use the `ansible-container push` command. If you previously logged into Docker Hub using `docker login`, then you should not need to authenticate again. If you need to authentication, you can use the *--username* and *--password* options. For more details and available options see [the *push* reference](http://docs.ansible.com/ansible-container/reference/push.html).

The following will perform the push:

```
# Set the working directory to the project root
$ cd symfony-mariadb-nginx

# Push the images 
$ ansible-container push 
```

### Generate the deployment playbook and role

Now we're ready to transform our orchestration document [ansible/container.yml](https://github.com/chouseknecht/symfony-mariadb-nginx/tree/master/ansible/container.yml) into deployment instrutions for OpenShift by running the `ansible-container shipit` command to generate an Ansible playbook and role.

For our example the images are out on Docker Hub. If you're using a private registry, you'll need to use the *--pull-from* option to specify the registry URL. For `shipit` details and available options see [the shipit reference](http://docs.ansible.com/ansible-container/reference/shipit.html).

The following will build the playbook and role:

```
# Set the working directory to the project root
$ cd symfony-mariadb-nginx

# Run the shipit command, using the IP address for your registry
$ ansible-container shipit openshift
```

### Run the deployment

The above added a playbook called *shipit-openshift.yml* to the *ansible* directory. The playbook relies on the `oc` client being installed and available in the PATH, and it assumes you already authenticated, and created the project.

When you're ready to deploy, run the following:

```
# Set the working directory to the ansible directory
$ cd symfony-mariadb-nginx/ansible

# Run the playbook
$ ansible-playbook shipit-openshift.yml
```

### Access the application

Start by logging into the OpenShift console using the URL displayed when you ran `oc cluster up`. Log in using the administrator account, and select the *symfony-mariadb-nginx* project. When the dashboard comes up, you'll see two running pods:

<img src="https://github.com/chouseknecht/symfony-mariadb-nginx/blob/images/img/dashboard.png" alt="dashboard view" />


To access the application in a browser, click on the *Application* menu, and choose *Routes*. You'll see a route exposing the *nginx* service. Click on the *Hostname* to open it in a browser.

### Load the database

If you're running the demo app, you can load the sample data similar to what you did previously, except this time we'll use the `oc` command. Start by getting the name of the *nginx* pod:

```
# List all pods in the project
$ oc get pods

NAME              READY     STATUS    RESTARTS   AGE
mariadb-3-3xxsf   1/1       Running   0          1h
nginx-3-gi4tj     1/1       Running   0          1h
```

Access the nginx pod, by running the `oc rsh` command followed by the name of your *nginx* pod. For example:

```
# Open a session to the pod
$ oc rsh nginx-3-gi4tj 
```

Now inside the *nginx* pod, run the following:

```
# Set the working directory to the web directory
$ cd /var/www/nginx

# Create the database schema
$ php bin/console doctrine:schema:create

# Load the data
$ php bin/console doctrine:fixtures:load --no-interaction

# Exit the container
$ exit
```

<h2 id="next">What's next?</h2>

If you followed through all of the examples, we covered a lot of ground. Under the covers we're using Ansible Container to build and manage the containers, so you'll want to use the following resources to learn more:

- [Project repo](https://github.com/ansible/ansible-container)
- [Docs Site](https://docs.ansible.com/ansible-container)

### Project configuration 

When we create the new project or the demo project, we're relying on the entrypoint script, symfony config and other files that get added into the *symfony* image during the `build` process. This gets handled in the [configure-symfony role](https://github.com/chouseknecht/symfony-mariadb-nginx/tree/master/ansible/roles/configure-symfony)

### Nginx, php-fpm and supervisor

The nginx service is configured by the [configure-php-fpm role](https://github.com/chouseknecht/symfony-mariadb-nginx/tree/master/ansible/roles/configure-php-fpm) as well as the [supervisord role](https://github.com/chouseknecht/symfony-mariadb-nginx/tree/master/ansible/roles/supervisord) during the build process. You'll want to take a look at these roles to understand how the container is configured. 

<h2 id="contributing">Contributing</h2>

If you work with this project and find issues, please [submit an issue](https://github.com/chouseknecht/symfony-mariadb-nginx/issues). 

Pull requests are welcome. If you want to help add features and maintain the project, please feel free to jump in, and we'll review your request quickly, and help you get it merged.

<h2 id="license">License</h2>

[Apache v2](https://www.apache.org/licenses/LICENSE-2.0)

<h2 id="dependencies">Dependencies</h2>

- [chouseknecht.nginx-conainer](https://galaxy.ansible.com/chouseknecht/nginx-container)

<h2 id="author">Author</h2>

[chouseknecht](https://github.com/chouseknecht)

