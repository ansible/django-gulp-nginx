project_name = $(shell basename $$PWD) 

.PHONY: build build_from_scratch build_debug clean run run_detached run_prod stop django_manage django_exec gulp_build

clean:
	@./ansible/clean.sh all
	docker volume rm ansible_postgres-data

build:
	@./ansible/clean.sh containers 
	-docker volume rm ansible_postgres-data
	ansible-container build

build_from_scratch: clean
	ansible-container build	

build_debug:
	@./ansible/clean.sh containers 
	-docker volume rm ansible_postgres-data
	ansible-container --debug build

run:
	ansible-container run

run_debug:
	ansible-container --debug run

run_detached:
	ansible-container run -d

run_prod:
	ansible-container run -d --production

stop:
	ansible-container stop

django_manage:
	@docker exec -it ansible_django_1 manage_django.sh $(filter-out $@,$(MAKECMDGOALS))

django_exec:
	@docker exec -it ansible_django_1 /bin/bash

gulp_build:
	@docker exec -it ansible_gulp_1 /node/scripts/gulp_build.sh

%:      
	@:
