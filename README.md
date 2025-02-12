# tlg-welcome-bot

Discord Welcome Bot - prompts users joining the server to change their name to the main of their WoW character and provides useful links.

## requires

AWS CLI, Terraform, Docker, Node, NPM, Circleci

## manual actions

terraform init

terraform destroy

terraform apply

./connect.sh

Then on server run the following to start the bot:

sudo docker run -it --rm -p 443:443 -v /home/admin/config.json:/usr/src/app/config.json dockerjam3s/tlg-bot