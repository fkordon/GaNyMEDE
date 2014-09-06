BASE_URL=http://lip6.fr/Fabrice.Kordon    # URL sur le site cible

# position relative locale du site compagnon de l'UE
LOCAL_WEB_SITE=WebSite
# nom sur le site cible du répertoire contenant le site compagnon
REMOTE_WEB_SITE=5I452-2014


# position locale relative du répertoire de cartographie
DATA_DIR=ConstructionData
# position locale relative du répertoire de cartographie
CARTO_DIR=ConstructionData/Cartographie
# position locale relative du répertoire contenant les scripts
SCRIPT_DIR=Scripts

help:
	@make present WHAT="Aide en ligne"
	@echo
	@echo "cartographie : génération de la cartographie du cours"
	@echo "web          : génération du site compagnon du cours"
	@echo "deploy       : déploiement sur une cible du sithe compagnon du cours"
	@echo "mooc         : construction de l'archive prête à être déployée"
	@echo "clean        : suppression des fichiers générés"
	@echo

present:
	@echo "======================================================================"
	@echo "UPMC - F. Kordon CC(2014)"
	@echo "$(WHAT)"
	@echo "======================================================================"
	

# generer le fichier dot pour construire la cartographe (pdf + liens) du cours
cartographie:
	@make present WHAT="Production de la cartographie du cours"
	@bash $(SCRIPT_DIR)/build_map.sh
	@bash $(SCRIPT_DIR)/build_map.sh `grep -v ^\# $(CARTO_DIR)/elements-cours.csv | cut -f 2 | sort -un`

web:
	make cartographie
	@make present WHAT="Génération du site compagnon de l'UE"
	bash $(SCRIPT_DIR)/deploy-sitecompagnon.sh

# deployer le site web 
deploy:
	@make present WHAT="Déploiement du site compagnon de l'UE"
	@mkdir $(HOME)/Desktop/$(REMOTE_WEB_SITE)
	cp -r $(LOCAL_WEB_SITE)/* $(HOME)/Desktop/$(REMOTE_WEB_SITE)
	@rm -rf $(HOME)/Desktop/$(REMOTE_WEB_SITE)/.svn
	@rm -rf $(HOME)/Desktop/$(REMOTE_WEB_SITE)/*/.svn
	@rm -f $(HOME)/Desktop/$(REMOTE_WEB_SITE)/.DS_Store
	@rm -f $(HOME)/Desktop/$(REMOTE_WEB_SITE)/*/.DS_Store
	@bash -c 'export COPYFILE_DISABLE=true ; cd $(HOME)/Desktop ; tar czf $(REMOTE_WEB_SITE).tgz $(REMOTE_WEB_SITE)'
	scp $(HOME)/Desktop/$(REMOTE_WEB_SITE).tgz fkordon@pagesperso-systeme.lip6.fr:public_html
	ssh fkordon@pagesperso-systeme.lip6.fr 'cd public_html; rm -rf $(REMOTE_WEB_SITE); tar xzf $(REMOTE_WEB_SITE).tgz ; rm -f $(REMOTE_WEB_SITE).tgz'
	@rm -rf $(HOME)/Desktop/$(REMOTE_WEB_SITE) $(HOME)/Desktop/$(REMOTE_WEB_SITE).tgz

mooc:
	@make present WHAT="Construction de l'archive de MOOC au format FUN"
	bash -c '$(SCRIPT_DIR)/deploy-mooc.sh'

clean:
	@make present WHAT="Nettoyage des fichiers générés"
	rm -f $(CARTO_DIR)/carto*.dot
	rm -f $(CARTO_DIR)/*.pdf
	rm -f $(LOCAL_WEB_SITE)/data/*
	rm -f $(LOCAL_WEB_SITE)/svg/*
	rm -f $(LOCAL_WEB_SITE)/content/semaine-*.html
	rm -f $(LOCAL_WEB_SITE)/semaine-*.php
	rm -f $(LOCAL_WEB_SITE)/pdf/*.pdf
	rm -f $(LOCAL_WEB_SITE)/TdM/semaine*.html
	rm -f $(DATA_DIR)/semaine-*.csv
	rm -f $(LOCAL_WEB_SITE)/functions/functions.php
	rm -f $(LOCAL_WEB_SITE)/functions/moddate.php

