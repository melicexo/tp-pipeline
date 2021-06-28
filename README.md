

## TP Terraform

 
**Objectif du projet :** 

Créer des ressources terraform afin d'héberger une application Scala qui permet de récupérer des tweets en temps réel. 

**Ressources créées dans ce projet :** 

- VPC
- EC2
- Kinesis Data Stream
- Kinesis Firehose
- Athena
- Glue
- IAM

**Pré-requis :** 

- Installer terraform
- Posséder un compte AWS avec un access key et un secret key générés et à portée de main

**Etapes de déploiement :**

1. Après récupération du projet, entrer dans le fichier "provider.tf" 

2. Initialiser les variables access_key et secret_key avec les identifiants de l'utilisateur souhaité

- access_key = ""
- secret_key = ""

3. Ouvrir l'invite de commandes sur le dossier

4. Entrer la commande suivante pour préparer le dossier à utiliser Terraform :


    

> terraform init



5. Pour vérifier le code et obtenir une synthèse des ressources qui seront créées, entrer la commande suivante :

    

> terraform plan

6. Pour lancer la création des ressources, entrer la commande suivante :

    

> terraform apply

7. Pour supprimer les ressources créées, entrer la commande suivante :

    

> terraform destroy




