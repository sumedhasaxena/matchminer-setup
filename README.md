
# matchminer-setup

This repository contains the combined setup to run [matchminer-ui](https://github.com/sumedhasaxena/matchminer-ui/) and [matchminer-api](https://github.com/sumedhasaxena/matchminer-api/).
Both these repos have been added as submodules to matchminer-setup repo.

**Clone the repo with submodules:**
```git clone --recurse-submodules git@github.com:sumedhasaxena/matchminer-setup.git```

**Launch:**

To launch the entire stack with a seed mongoDB user:
Run ```./setup.sh --dev true```

Without a seed mongoDB user:
Run ```./setup.sh --dev false```

**Detailed Setup**:

*matchminer-ui:*

This code has ben forked from matchminer-ui codebase developed at DFCI. (https://github.com/dfci/matchminer-ui)

Following setup is needed to run matchminer-ui in prod env:
**SSL certs:**

- Navigate to the directory *matchminer-setup/matchminer-ui/*.
- Create a folder named 'certificates' under *matchminer-setup/matchminer-ui/*
- Generate a SSL certificate and private key pair and place them inside 'certificates' folder.
- Also place the cert pair onto the server hosting this application.

DockerFile Update:

Update Dockerfile under matchminer-ui to add SSL cert info:    

>     COPY certificates/my_ssl_cert.crt /etc/ssl/certs
>     COPY certificates/my_ssl_cert.key /etc/ssl/private
Nginx.conf Update:
