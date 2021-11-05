# `googlePubsubR`

This library offers an easy to use interface for the Google Pub/Sub REST API
(docs [here](https://cloud.google.com/pubsub/docs/reference/rest)).

Not an official Google product.

## Setup

You can install the package (not on CRAN for the time being) from Github:
```r
devtools::install_github("andodet/googlePubsubR")
```

In order to use the library, you will need:
* An active GCP project
* The Pub/Sub API correctly activated
* JSON credentials for a service accont or another method of authentication (e.g token)
* A `GCP_PROJECT` env variable set with a valid GCP project id

## Usage

On a very basic level, the library can be used to publish messages, pull and acknowledge them.  
The following example shows how to:

1. Create topics and subscriptions
2. Encode a dataframe as a Pub/Sub message
3. Publish a message
4. Pull and decode messages from a Pub/Sub subscription
5. Delete resources

```r
library(googlePubsubR)
library(base64enc)
library(jsonlite)

# Create resources
topic_readme <- topics_create("readme-topic")
sub_readme <- subscriptions_create("readme-sub", topic_readme)

# Prepare the message
msg <- mtcars %>%
  toJSON(auto_unbox = TRUE) %>%
  charToRaw() %>%
  # Pub/Sub expects a base64 encoded string
  base64encode() %>%
  PubsubMessage() 

# Publish the message!
topics_publish(msg, topic_readme)

# Pull the message from server
msgs_pull <- subscriptions_pull(sub_readme)

msg_decoded <- msgs_pull$receivedMessages$message$data %>%
  base64decode() %>%
  rawToChar() %>%
  fromJSON()

head(msg_decoded)

# Prints
# mpg cyl disp  hp drat    wt  qsec vs am gear carb
# Mazda RX4         21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
# Mazda RX4 Wag     21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
# Datsun 710        22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
# Hornet 4 Drive    21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
# Hornet Sportabout 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
# Valiant           18.1   6  225 105 2.76 3.460 20.22  1  0    3    1

#Cleanup resources
topics_delete(topic_readme)
subscriptions_delete(sub_readme)
```

## Use cases

The main use-cases for Pub/Sub messaging queue:

* Stream data into [Dataflow](https://cloud.google.com/dataflow) pipelines
* Trigger workflows hosted in Cloud Run or Cloud Functions
* Expand interactivity in Shiny dashboards (more on this [here](inst/shiny/consumer_example/readme.md)).
* Add event driven actions in [`{plumbr}`](https://www.rplumber.io/)
