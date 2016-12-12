# django-gulp-nginx

A framework for building containerized [django](https://www.djangoproject.com/) applications. Utilizes [Ansible Container](https://github.com/ansible/ansible-container) to manage each phase of the application lifecycle, and enables you to begin developing immediately in containers.

The following topics will help you get started: 

- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Developing](#developing)
- [Adding Service](#adding)
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

The build process takes a few minutes to complete, taking longer the first time you run it. As it executes, task names will scroll across your terminal session marking its progression through the Ansible playbook, [main.yml](./blob/master/ansible/main.yml). Once completetd, you'll have a local set of images for your project.

Next, start the containers: 

```
# Start the containers
$ ansible-container run
```

You now have have 3 containers running in development mode, ready for you to begin building your app. To view your app, open a browser and go to [http://localhost:8080](http://localhost:8080). And to log into the django admin site, go to [http://localhost:8080/admin](http://localhost:8080/admin)

<h2 id="developing">Developing</h2>
 
When you start the containers by running `ansible-container run`, they start in development mode, which means that the *dev_overrides* section of each service definition in [ansbile/container.yml](./ansible/container.yml) takes precedence, causing the gulp, django and postgresql services to start, and the nginx service to stop.  

The frontend code can be found in the *src* directory, and the backend django code is found in the *project* directory. You can begin macking changes right away, and as you do you'll see the results reflected in your browser almost immediately.

Here's a brief overview of each of the running services:

### gulp 

While developing, the gulp container will be running, and actively watching for changes to files in the *src* directory tree. The *src* directory is where custom frontend components (i.e. html, javascript, css, etc.) live, and as new files are created or existing files modified, the gulp service will compile the updates, place results in the *dist* directory, and using [browsersync](https://browsersync.io/), refresh your browser.

In addition to compiling the frontend components, the gulp service will proxy requests beginning with */static* or */admin* to the django service. The proxy settings are configurable in *gulpfile.js*, so as you add additional routes to the django service, you can expand the number of paths forwarded by the gulp service. 

NOTE
> *As you add new routes to the backend, be sure to update the nginx configuration by modifying [ansible/main.yml](./ansible/main.yml), and adjusting the parameters passed to the chouseknecht.nginx-container-1 role. Specifically, you'll need to update the PROXY_LOCATION value.*

### django

The django service provides the backend of the application. During development the *runserver* process executes, and accepts requests from the gulp service. The source code to the django app lives in the *project* directory tree. To add additional python and django modules,add the module names and versions to *requirements.txt*, and run the `ansible-container build` command to add them to the django image.

When the django container starts, it waits for the postgresql database to be ready, and then it performs migrations, all before starting the server process. Use `make django_manage makemigrations` and `make django_manage migrate` to create and run migrations during develoopment.  

### postgresql

The posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume. Modify [ansible/condtainer.ym](./ansible/container.yml) to set the database name, and credentials.  

<h2 id="adding">Adding Services</h2>

More information coming soon... 

<h2 id="testing">Testing</h2>

After you've made changes to the app, and you're ready to test, you'll first run `ansible-container build` to create a new set of images containing the latest code. During the build process, the *project* directory, which containins your custom django files, will be copied into the django image at */django*, and your frontend assets, contained in *src*, will be compiled and copied to the *dist* directory, and then copied into the nginx image at */static*.

Once the new images are built, run the command `ansible-container run --production` to test the images. This will start containers in production mode, ignoring the *dev_overrides * section of each service definition in `container.yml`, and executing the containers as if they were deployed to production. You'll see the django, nginx and postgresql containers start, and the gulp container stop.

### django

In production this service will run the gunicorn process to accept requests from the nginx service. Just as before, when the service starts it will wait for the postgresql database to become available, and then perform migrations, before starting the server process. 

### nginx 

This service will respond to requests for frontend assets, and proxy requests to django service endpoints. Before running `ansible-container build`, if you added new routes to your django application, be sure to update the nginx configuration by modifying [ansible/main.yml](./ansible/main.yml), and adjusting the PROXY_LOCATION parameter passed to the ansible.nginx-container role. This will impact the *nginx.conf* file that gets added to the image.

### postgresql

Just as before, the posgresql sevice provides the django service with access to a database, and by default stores the database on the *postgres-data* volume.

NOTE
> *If you start the image build process by running `make build`, the *postgres-data* volume will be deleted, and the applciation will start with an empty database.*

<h2 id="openshift">Deploying</h2>

A deployment example will be added. Stay tuned.

<h2 id="contributing">Contributing</h2>

If you work with this project and find issues, please [submit an issue](https://github.com/ansible/django-gulp-nginx/issues). 

Pull requests are welcome. If you want to help add features and maintain the project, please feel free to jump in, and we'll review your request quickly, and help you get it merged.

<h2 id="license">License</h2>

[Apache v2](https://www.apache.org/licenses/LICENSE-2.0)

<h2 id="dependencies">Dependencies</h2>

- [ansible.nginx-container](https://galaxy.ansible.com/ansible/nginx-container)

<h2 id="author">Authors</h2>

View [AUTHORS](./AUTHORS) for a list contributors. Thanks everyone!



