library(future)
library(parallel)
library(jsonlite)
library(googlePubsubR)

plan(multisession)
cl <- makeCluster(2)

# Set up an example topic and subscription
pubsub_auth()
mock_topic <- topics_create('vignette-topic')
mock_sub <- subscriptions_create('vignette-sub', 'vignette-topic',
                                 ack_deadline = 10)

# Process data from a Pub/Sub message (faking a long computation)
something_slow <- function(msg) {
  df <- msg$receivedMessages$message$data %>% 
    msg_decode() %>% 
    fromJSON()
  
  df$a <- df$a + 1
  df$b <- df$b + 1
  # For the sake of the example, it is crucial that this function sleeps for longer than the
  # ack_deadline, forcing the message to be re-delivered
  Sys.sleep(15)
  
  return(df)
}

# Create and publish a message containing some data to be consumed
msg <- data.frame(
  a = 1,
  b = 2
) %>% 
  toJSON() %>% 
  msg_encode() %>% 
  PubsubMessage()

topics_publish(msg, mock_topic)

# Decode message and start slow computation in a parallel session
msg_pull <- subscriptions_pull(mock_sub)
new_data %<-% something_slow(msg_pull)  # non-blocking future

# Check if data processing has finished. If not, we'll increase the ack_deadline by 5 seconds
while(!resolved(futureOf(new_data))) {
  print("Extending ack deadline")
  subscriptions_modify_ack_deadline(mock_sub, msg_pull$receivedMessages$ackId, 5)
  Sys.sleep(1)
}

# Everything has finished, we can now ack the message
subscriptions_ack(msg_pull$receivedMessages$ackId, mock_sub)

# Print new data to check everything is good
new_data
subscriptions_pull(mock_sub)

# Cleanup resources
topics_delete(mock_topic)
subscriptions_delete(mock_sub)
stopCluster(cl)
