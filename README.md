# scripts
# from Animus:
  mkdir -p Dropbox/ViziApps/GitHub/scripts
  cd Dropbox/ViziApps/GitHub/scripts/
  cp ~/work/wintermute/sandboxes/bob/scripts/* .
  vim README.md
  git init
  git add README.md 
  git commit -m "first commit"
  git remote add origin https://github.com/alvinkrebs/scripts.git
  git push -u origin master
  git add Try*.q
  git commit -m "Try scripts"
  git remote add origin https://github.com/alvinkrebs/scripts.git
  git push -u origin master

# from the OlMac
  git fetch https://github.com/alvinkrebs/scripts.git
  vim TryCred.q
  git add TryCred.q
  git commit -m "Remove debugging x val"
  git push origin master
