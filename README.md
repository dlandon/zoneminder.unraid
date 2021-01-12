## Zoneminder Docker for Unraid
(Current version: 1.34)

We have set up a GoFundMe to fund the development of a new Docker that will be for Zoneminder and ES/ML with all the ES/ML modules pre-configured and for maintenance and support going forward.

[GoFundMe](https://www.gofundme.com/f/maintenance-of-zoneminder-docker-with-es-and-ml?utm_source=customer&utm_medium=copy_link&utm_campaign=p_cf+share-flow-1)

### About
This is an easy to run dockerized image of [ZoneMinder](https://github.com/ZoneMinder/zoneminder) along with the the [ZM Event Notification Server](https://github.com/pliablepixels/zmeventnotification).  

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions of Zoneminder.

You can donate [here](https://www.paypal.com/us/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=EJGPC7B5CS66E).

#### Usage

To access the Zoneminder gui, browse to: `https://<your host ip>:8443/zm` or `http://<your host ip>:8080/zm` if `-p 8080:80/tcp` is specified.

The zmNinja Event Notification Server is accessed at port `9000`.  Security with a self signed certificate is enabled.  You may have to install the certificate on iOS devices for the event notification to work properly.

#### Troubleshooting when the docker fails

If you have a situation where the docker fails to start, you can set an environemtnt variable when the docker is started and MySql and Zoneminder will not be started.  This will keep the docker running so you can get into a command line in the docker and troubleshoot the problem.

Create an environment variable:
NO_START_ZM="1"

MySql and Zoneminder will not be started.

Get into a command line in the docker and troubleshoot your issue by using the following commands to start MySql and zonemonder and fix any errors/problems with them starting.

service mysql start

service zoneminder start
