
# distributed algorithms, n.dulay, 8 jan 18
# Makefile, v1

MAIN    = System1.main
PROJECT = da347
NETWORK = $(PROJECT)_network

COMPOSE = docker-compose -p $(PROJECT) 

compile:
	mix compile

clean:
	mix clean

build:	
	$(COMPOSE) build

up:	
	MAIN=$(MAIN) $(COMPOSE) up 

down:
	$(COMPOSE) down
	make show

show:
	@echo ----------------------
	@make ps
	@echo ----------------------
	@make network 

ps:
	docker ps -a -s

network net:
	docker network ls

inspect:
	docker network inspect $(NETWORK)

netrm:
	docker network rm $(NETWORK) 
conrm:
	docker rm $(ID)

done:  # place within an 'if' in ~/.bash_logout
	docker rm -f `docker ps -a -q`
	docker network rm da347_network

