# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# grep the version from the mix file
# VERSION=$(shell ./version.sh)

.PHONY: default build run stop kill

default:
	@echo "Default:"

############################
# Docker
############################

build: ## Build the container
	docker build -t $(APP_NAME) .

build-nc: ## Build the container without caching
	docker build --no-cache -t $(APP_NAME) .

run: ## Run container on port configured in `config.env`
	docker container run -itd --rm -v $(pwd)/src:/var/www/html --env-file=./config.env -p=$(HOST_PORT):$(PORT) --name="$(APP_ALIAS)" $(APP_NAME)

stop: ## Stop and remove a running container
	docker container stop $(APP_ALIAS) 
	## ; docker rm -f $(APP_ALIAS); docker rmi -f $(APP_ALIAS)

kill: ## be careful be aware 
	./apocalipse.sh

ps:
	docker ps -la

log:
	docker logs -f $(APP_ALIAS) 
	
############################
# docker-compose
############################

cmpup:
	docker-compose up -d
	
cmpbuild:
	docker-compose build --force-rm
	
cmpstop: ## Stop services only
	docker-compose stop

cmpdown: ## Stop and remove containers, networks..
	docker-compose down 

cmpdownv: ## Down and remove volumes
	docker-compose down --volumes 

cmpdownrmi: ## Down and remove images <all|local>
	docker-compose down --rmi all 

cmplogs:
	docker-compose logs -f

cmpimages: 
	docker-compose images	

cmpps:
	docker-compose ps
