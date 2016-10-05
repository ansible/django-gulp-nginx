# django-gulp-nginx

[![Build Status](https://travis-ci.org/chouseknecht/django-gulp-nginx.svg?branch=master)](https://travis-ci.org/chouseknecht/django-gulp-nginx)

A web application built and managed with [Ansible Container](https://github.com/ansible/ansible-container).

The application includes a Django rest API on the backend, and an AngularJS single page application (SPA) on the frontend. Together they combine to create a simple social media app called *Not Goolge Plus*, where you can register, update your profile, and share your thoughts with the world. 

To view the demo start by setting up your development environment. Later, after you've made some changes, test the application in production mode, and finally deploy your changes to the cloud using a local OpenShift instance.

The application may sound simplistic, but it incorporates the architecture and tools typical of a modern web app, allowing you to see first hand how Ansible Container makes it easy to manage a containerized app through each phase of the development lifecycle.

## Requirements

Before you can run the demo, you'll need a couple of things:

 - Ansible Container installed from source. See our [Running from source guide](http://docs.ansible.com/ansible-container/installation.html#running-from-source) for assistance.  
 - Docker Engine or Docker for Mac.
 - Ansible 2.1+, if you plan to run through the deployment  

## Getting Started

You'll start by copying the project, building the images, and launching the app in development mode. When you're done you'll be able to tour the *Not Google Plus* site running live in your environment. 

### Copy the project

To get started, use the Ansible Container `init` command to create a local copy of this project. In a terminal window, run the 
following commands to create the copy: 

```
# Create a directory called 'demo'
$ mkdir demo

# Set the working directory to demo
$ cd demo

# Initialize the project 
$ ansible-container init chouseknecht.django-gulp-nginx 
```

You now have a copy of the project in a directory called *demo*. Inside *demo/ansible* you'll find a `container.yml` file 
describing in [Compose](http://docs.ansible.com/ansible-container/container_yml/reference.html) the services that make up the application, and an Ansible playbook called `main.yml` containing a set of plays for building the application images. 

### Build the images

To run the application, you'll first need to build the images, and you can start the build by running the following command:

```
# Start the image build process
$ ansible-container build
```

![Building the images](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/build_01.png)

The build process launches a container for each service along with a build container. For each service container, the base image is the 
image specified in `container.yml`. The build container runs the `main.yml` playbook, and executes tasks on each of the containers. You'll 
see output from the playbook run in your terminal window as it progresses through the tasks. When the playbook completes, each image will
be `committed`, creating a new set of base images.

When execution stops, use the `docker images` command to view the new images:

```
# View the images
$ docker images

REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
demo-django                         20161205170642      dbe68f4e3c74        About an hour ago   1.28 GB
demo-django                         latest              dbe68f4e3c74        About an hour ago   1.28 GB
demo-nginx                          20161205170642      5becc50f69a9        About an hour ago   270 MB
demo-nginx                          latest              5becc50f69a9        About an hour ago   270 MB
demo-gulp                           20161205170642      0644893c80d7        About an hour ago   508 MB
demo-gulp                           latest              0644893c80d7        About an hour ago   508 MB
```

### Run the application

Now that you have the application images built in your environent, you can launch the application and log into *Not Google Plus*. Run the following command to start the application:

```
# Launch the demo
$ ansible-container run
```
You should now see the output from each container streaming in your terminal window. The containers are running in the foreground, and they are running in *development mode*, which means that for each service the *dev_overrides* directive is being included in the configuration. For example, take a look at the *gulp* service definition found in `container.yml`:

```
  gulp:
    image: centos:7
    user: '{{ NODE_USER }}'
    working_dir: '{{ NODE_HOME }}'
    command: ['/bin/false']
    environment:
      NODE_HOME: '{{ NODE_HOME }}'
    volumes:
      - "${PWD}:{{ NODE_HOME }}"
    dev_overrides:
      command: [/usr/bin/dumb-init, /usr/bin/gulp]
      ports:
      - 8080:{{ GULP_DEV_PORT }}
      - 3001:3001
      links:
      - django
    options:
      kube:
        state: absent
      openshift:
        state: absent
```

In development *dev_overrides* takes precedence, so the command ``/usr/bin/dumb-init /usr/bin/gulp* will be executed, ports 8080 and 3001 will be exposed, and the container will be linked to the *django* service container.

If you were to tun the *gulp* service in production, *dev_overrides* would be ignored completely. In production the ``/bin/false`` command will be executed, causing the container to immediately stop. No ports would be exposed, and the container would not be linked to the django container.

Since the frontend tools gulp and browsersync are only needed during development and not during production, we use *dev_overrides* to manage when the container executes.

The same is true for the nginx service. Take a look at the service definition in `container.yml`, and you'll notice it's configured opposite of the gulp service:

```
  nginx:
    image: centos:7
    ports:
    - {{ DJANGO_PORT }}:8000
    user: nginx
    links:
    - django
    command: ['/usr/bin/dumb-init', 'nginx', '-c', '/etc/nginx/nginx.conf']
    dev_overrides:
      ports: []
      command: /bin/false
    options:
      kube:
        runAsUser: 1000
```

In development the nginx service runs the ``/bin/false`` command, and immediately exits. But in production it starts the 
``nginx`` process, and takes the place of the gulp service as the application's web server.

### Tour the site 

Now that you have the application running, lets check it out! Watch the video below, and follow along on your local site to register, log in, and create posts. Your site will be reachable at [http://localhost:8080](http://localhost:8080), and you can browse the API directly at [http://localhost:8080/api/v1/](http://localhost:8080/api/v1/).

Click the image below to watch the video:

[![Site Tour](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/demo.png)](https://youtu.be/XVOIVhcYd8M)

### Stopping the containers

Once you're finished, you can press `ctrl-c` to kill the containers. This will signal Docker to kill the processes running inside the containers, and shut the containers down. This works when the containers are running in the foreground, streaming output to your terminal window.

You can also run `ansible-container stop`. For containers running in the foreground, open a second terminal window, set the working directory to your *demo* project, and run the command. It will terminate all containers associated with the project, regardless wether they're running in the foreground or in the backgound.

## Testing the application

If you make code changes, and you want to test, you'll begin by building a fresh set of images that contain your code changes. During the build process the latest code gets added to the nginx image. So if you actually modified some code, go ahead and run the `build` command as follows, otherwise you can skip this step:

```
# Start the build process
$ ansible-container build
```  

Once the build process completes, you'll have a new set of images, which you can view using `docker images`

```
# View the images once again
$ docker images

REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
demo-django                         20161205192107      103a28329385        4 minutes ago       2.31 GB
demo-django                         latest              103a28329385        4 minutes ago       2.31 GB
demo-gulp                           20161205192107      b264122208b5        5 minutes ago       534 MB
demo-gulp                           latest              b264122208b5        5 minutes ago       534 MB
demo-nginx                          20161205192107      7206eff9bf9b        5 minutes ago       295 MB
demo-nginx                          latest              7206eff9bf9b        5 minutes ago       295 MB
demo-django                         20161205170642      dbe68f4e3c74        2 hours ago         1.28 GB
demo-nginx                          20161205170642      5becc50f69a9        2 hours ago         270 MB
demo-gulp                           20161205170642      0644893c80d7        2 hours ago         508 MB
```

You now have a newer set of images with your code changes baked into the nginx image. Now when you start the application in production mode or deploy it, your changes will be available.

### Start in production mode 

For testing you want to launch the application in *production mode*, so that it runs exactly the same as it does when deployed to the cloud. As we pointed out earlier, when run in production the *dev_overrides* settings are ignored, which means we'll see the gulp container stop and the nginx container start and run as our web server. To start the application in production mode, run the following command:

```
# Start the appliction in production mode
$ ansible-container run --production
```

The following video shows the application starting with the ``--production`` option. Click the image below to watch the video:

[![Testing](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/production.png)](https://youtu.be/ATpYJhG1RV0)

## Deploy the application

Once the application passes testing, it's time to deploy it to production. To demonstrate, we'll create a local instance of OpenShift, push images to its registry, generate a deployment playbook, run it, and check the results.

### Create a local OpenShift instance

To create an OpenShift instance you'll install the ``oc`` command line tool, and then run `oc cluster up`. The cluster runs in containers, making the install process almost trivial.

You'll find instructions in our [Install and Configure OpenShift guide](http://docs.ansible.com/ansible-container/configure_openshift.html) to help you create an instance. One available installation method is the Ansible role [chouseknecht.cluster-up-role](https://galaxy.ansible.com/chouseknecht/cluster-up-role), which is demonstrated in the following video:

[![Creating an OpenShift instance](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/cluster.png)](https://youtu.be/iY4bkHDaxCc)

To use the role, you'll need Ansible installed. Also, note in the video that the playbook is copied from the installed role's file structure. You'll find the playbook, *cluster-up.yml*, in the *files* subfolder.

As noted in the role's [README](https://github.com/chouseknecht/cluster-up-role/blob/master/README.md), if you have not already added the *insecure-registry* option to Docker, the role will error, and provide the subnet or IP range that needs to be added. You'll also need to add the value of the *openshift_hostname* option, which by default is *local.openshift*. For more about adding the --insecure-registry option see [Docker's documentation](https://docs.docker.com/registry/insecure/). 

### Create an OpenShift project

Now that you have an OpenShift instance, run the following to make sure you're logged into the cluster as *developer*, and create a *demo* project:

```
# Verify that we're logged in as the *developer* user
$ oc whoami
developer

# Create a demo project
$ oc new-project demo

Now using project "demo" on server "https://...:8443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git

to build a new example application in Ruby.
```

### Push the images

Before starting the application on the cluster, the images will need to be accessible, so you'll push them to the *demo* repository on the local registry.

If you ran the role to create the OpenShift instance or worked through our guide, then a new hostname, *local.openshift*, was created for accessing the registry, and the *developer* account now has full admin access. So you'll employ both of these as you execute the following commands to push the images:   

```
# Set the working directory to the demo project
$ cd demo

# Push the demo images to the local registry 
$ ansible-container push --push-to https://local.openshift/demo --username developer --password $(oc whoami -t)
```

The following video shows the project's images being pushed to the local registry:

[![Push images](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/push.png)](https://youtu.be/KklXsFKd8gQ)

### Generate the deployment artifacts 

Now you'll generate a playbook and role that are capable of deploying the application. From the *demo* directory, execute the `shipit` command as pictured below, passing the `--pull-from` option with the URL to the local registry:

```
# Generate the deployment playbook and role
$ ansible-container shipit openshift --pull-from https://local.openshift/demo
```
Running the above creates, a playbook, *shipit-openshift.yml*, in the *ansible* directory, and a role, *demo-openshift*, in the *ansible/roles* directory as demonstrated in the following video:

[![Run shipit](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/shipit.png)](https://youtu.be/4a8WKO5Kjlo)

### Deploy!

You now have the deployment playbook and role. But before you run the playbook, you'll need to create an inventory file. If you're not familiar with Ansible, not to worry. A playbook runs a set of plays on a list of hosts, and the inventory file holds the list of hosts. In this case we want to execute the plays on our local workstation, which we can refer to as *localhost*, and so we'll create an inventory file containing a single host named *localhost*. Run the following to create the inventory file:

```
# Set the working directory to demo/ansible
$ cd ansible

# Create an inventory file
$ echo "localhost">inventory
```
Now from inside the *demo/ansible* directory, run the following to launch the *Not Google Plus* site on your OpenShift instance:

```
# Run the playbook
$ ansible-playbook -i inventory shipit-openshift.yml
```
Once the playbook completes, the application will be running on the cluster, and you can log into the console to take a look. To access the application, you'll need the hostname assigned to the route, and you can discover that by clicking on *Applications*, and choosing *Routes*. From there click on the hostname link, and the application will be opened in a new browser tab.

Watch the following video to see the full deployment:  

[![Deploy the app](https://github.com/chouseknecht/django-gulp-nginx/blob/images/images/deploy.png)](https://youtu.be/9i6iGMLyr44)

