# django-gulp-nginx

Simple Django web application to demo [Ansible Container](https://github.com/ansible/ansible-container).

Ansible Container makes it possible to build container images using Ansible Playbooks rather than Dockerfile, and
provides the tools you need to manage the complete container lifecycle from development to deployment.

With Ansible Container you get: 

- Tools you already know: Ansible and Docker Compose
- Highly reusable code by way of Ansible roles
- Easy to read and understand image build instructions
- Repeatable image build process
- Auto-generated deployment artifacts directly from your orchestration document


## Requirements

[Ansible Container](https://github.com/ansible/ansible-container)

Ansible Container requires access to a running Docker Engine or Docker Machine. For help with the installation, see
our [installation guide](https://docs.ansible.com/ansible-container#install).


## Usage

To run this app locally, create a project directory and then initialize it with Ansible Container, specifying this 
project as the template:

```
$ mkdir demo
$ cd demo
$ ansible-container init chouseknecht.django-gulp-nginx 
```

From your project directory build the images:

```
$ ansible-container build
```

And finally, from your project directory run the app:

```
$ ansible-container run
```
 
