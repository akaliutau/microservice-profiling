# About

This project describes various techniques to tune up and profile Spring Boot - based (and essentially any Java) applications

# VisualVM

Download, unpack and run VisualVM app:

```
./bin/visualvm
```

## Profiling local application

In other terminal run Spring Boot application with max memory heap 256MB:

```
java  -Xmx256m -jar ./target/worker-0.0.1.jar
```

In VisualVM go to the Applications -> Local -> worker-0.0.1.jar and open it, getting in such way the access to all 
JVM parameters, including CPU, Heap/Metaspace, loaded classes and threading information.

## Profiling applications running inside Docker container

Build an image with app and push it to GCloud private docker registry, f.e. :

```
mvn clean package -DskipTests
sudo docker build -t worker:0.0.1 .
```

Docker image can be tested with the help of command (`ctrl+shift+c` to stop):
```
sudo docker run -p 8080:8080 -p 9010:9010 worker:0.0.1
```

Go to File -> Add JMX Connection and create a new connection for localhost:9010, no authentication. The access to application 
can be got the same way as for local running JVM

## Profiling applications running at GCE

(1) Prepare your application for GCE. Tag the image and push it to the registry:

```
source set_env.sh
sudo docker tag worker:0.0.1 eu.gcr.io/$GOOGLE_CLOUD_PROJECT/worker:v1
sudo docker push eu.gcr.io/$GOOGLE_CLOUD_PROJECT/worker:v1
```
Go to https://console.cloud.google.com/gcr/images/ and check the image does exist, or use the command:

```
docker pull eu.gcr.io/$GOOGLE_CLOUD_PROJECT/worker:v1
```

(2) Create a simple VM Instance on the basis of pushed Docker image:

```
gcloud compute instances create-with-container worker-instance-1 \
  --project=$GOOGLE_CLOUD_PROJECT \
  --zone=europe-west2-c \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=362163460144-compute@developer.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
  --tags=http-server,https-server \
  --image=projects/cos-cloud/global/images/cos-stable-93-16623-102-8 \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name=worker-instance-1 \
  --container-image=eu.gcr.io/$GOOGLE_CLOUD_PROJECT/worker:v1 \
  --container-restart-policy=always \
  --container-tty \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=container-vm=cos-stable-93-16623-102-8
```
Note, that some arguments can change over time, for example, the version of COS, or can be different, as the id of default
compute service account

The command should show the instance was created:

```
Created [https://www.googleapis.com/compute/v1/projects/GOOGLE_CLOUD_PROJECT/zones/europe-west2-c/instances/worker-instance-1].
NAME               ZONE            MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP    STATUS
worker-instance-1  europe-west2-c  e2-micro                   10.154.15.219  34.142.95.167  RUNNING
```

(3) Use port-forwarding for port=9010:

```
gcloud compute ssh https://www.googleapis.com/compute/v1/projects/$GOOGLE_CLOUD_PROJECT/zones/europe-west2-c/instances/worker-instance-1 -- -L 9010:localhost:9010
```

(4) Go to File -> Add JMX Connection and create a new connection for localhost:9010, no authentication. 
The access to application can be got the same way as for local running JVM

# References

[1] [VisualVM](https://visualvm.github.io/) - a profiling standalone tool which runs on any compatible JDK