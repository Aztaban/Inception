COMPOSE_FILE = srcs/docker-compose.yml
LOGIN = mjusta

all: up

up:
	mkdir -p /home/$(LOGIN)/data/mariadb
	mkdir -p /home/$(LOGIN)/data/wordpress
	docker-compose -f $(COMPOSE_FILE) up --build -d

down:
	docker-compose -f $(COMPOSE_FILE) down

stop:
	docker-compose -f $(COMPOSE_FILE) stop

start:
	docker-compose -f $(COMPOSE_FILE) start

restart: down up

logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

ps:
	docker-compose -f $(COMPOSE_FILE) ps

clean:
	docker-compose -f $(COMPOSE_FILE) down --volumes --remove-orphans

fclean: clean
	docker system prune -af
	sudo rm -rf /home/$(LOGIN)/data/mariadb
	sudo rm -rf /home/$(LOGIN)/data/wordpress

re: fclean all

.PHONY: all up down stop start restart logs ps clean fclean re

