project_name = $(shell basename $$PWD) 

.PHONY: build build_from_scratch build_debug clean clean_containers
	run run_prod stop django_manage django_exec gulp_build

clean:
	@./scripts/clean.sh all
	-docker volume rm djangogulpnginx_postgres-data
	-docker volume rm djangogulpnginx_temp-space

clean_containers:
	@./scripts/clean.sh containers
	-docker volume rm djangogulpnginx_postgres-data
	-docker volume rm djangogulpnginx_temp-space

build:
	@./scripts/clean.sh containers 
	-docker volume rm djangogulpnginx_postgres-data
	-docker volume rm djangogulpnginx_temp-space
	ansible-container build

build_from_scratch: clean
	ansible-container build	

build_debug:
	@./scripts/clean.sh containers 
	-docker volume rm djangogulpnginx_postgres-data
	-docker volume rm djangogulpnginx_temp-space
	ansible-container --debug build

run:
	ansible-container run

run_debug:
	ansible-container --debug run

run_prod:
	ansible-container run --production

stop:
	ansible-container stop

django_manage:
	@docker exec -it djangogulpnginx_django_1 manage_django.sh $(filter-out $@,$(MAKECMDGOALS))

django_exec:
	@docker exec -it djangogulpnginx_django_1 /bin/bash

gulp_build:
	@docker exec -it djangogulpnginx_gulp_1 /node/scripts/gulp_build.sh

%:      
	@:
