library(httr)
library(jsonlite)
library(DT)
library(dplyr)
library(twitteR)
library(syuzhet)
library(scales)
library(readr)

spotifyKey <- "c432b36c21724d2989baf7d4d8a6bfd3"
spotifySecret <- "047d74d4926c44ec8681c236d702dff9"


response = POST(
  'https://accounts.spotify.com/api/token',
  accept_json(),
  authenticate(spotifyKey, spotifySecret),
  body = list(grant_type = 'client_credentials'),
  encode = 'form',
  verbose()
)

token = content(response)$access_token

HeaderValue = paste0('Bearer ', token)



new_releases_url <- "https://api.spotify.com/v1/browse/new-releases"
getNewReleases <- GET(new_releases_url, add_headers(Authorization = HeaderValue))
newReleasesContent <- jsonlite::fromJSON(toJSON(content(getNewReleases)))


newreleases<-data.frame(matrix(unlist(newReleasesContent$albums$items$id), 
                               nrow=newReleasesContent$albums$total, byrow=T),stringsAsFactors=FALSE)
##spotify<-newreleases[1:30,]
spotify<-unique(newreleases[,1])

get.tracks <- function(spotify){
  albumTracksURL <- paste("https://api.spotify.com/v1/albums/", spotify, "/tracks?limit=50", sep="")
  getTracks <- GET(albumTracksURL, add_headers(Authorization = HeaderValue))
  albumTracks <- jsonlite::fromJSON(toJSON(content(getTracks)))
  
  ids <- data.frame(matrix(unlist(albumTracks$items$id), 
                           nrow=albumTracks$total, byrow=T),stringsAsFactors=FALSE)
  
  names <- data.frame(matrix(unlist(albumTracks$items$name), 
                             nrow=albumTracks$total, byrow=T),stringsAsFactors=FALSE)
  artists<-albumTracks$items$artists
  artists1<-do.call(rbind, lapply(artists, function(x) do.call(cbind, lapply(x[c('id', 'name')], toString))))
  
  
  result <- cbind(ids, names, artists1)
  
  colnames(result) <- c("ID", "NAME", "ARTIST ID", "ARTIST NAME")
  
  return(result)
}

df <- lapply(spotify, get.tracks)

result <- do.call(rbind, df)
result_final<-result

names(result_final) <- c("ID", "NAME", "ARTIST ID", "ARTIST NAME")
final<-result_final

final1<-final[!duplicated(final), ]

##Genius

client_id <- "3y_TtkyL_4l7CkeLVymC7_MKemb5Ik3A0XG9lxJ-y7Zav4b9gPXYzkbfmXfKm-V1"
client_secret <- "ff64O8-DpJYJlhVRszdxO1qnuX7VpL9tWSW33a3uwmPJp0LpbGDczK4PB6LMach_C6M-00-WPE9lwcV6zXo-DQ"

token <- "w3BQHoOssKNneb9agreuxcdnrDyxS7jRktAci6qzB5RKypgvH-DA5SvDI5bDzxAW"

HeaderValue = paste0('Bearer ', token)

response = POST(
  'https://api.genius.com/token',
  accept_json(),
  authenticate(client_id, client_secret),
  body = list(grant_type = 'client_credentials'),
  encode = 'form',
  verbose()
)

##token = content(response)$access_token
token <- "w3BQHoOssKNneb9agreuxcdnrDyxS7jRktAci6qzB5RKypgvH-DA5SvDI5bDzxAW"
HeaderValue = paste0('Bearer ', token)

final1$NAME_and_ARTISTS <- paste(final1$NAME,final1$`ARTIST NAME`,sep = " ")
final1$NAME_and_ARTISTS<-gsub(" ", "%20", final1$NAME_and_ARTISTS, fixed=TRUE)

##final1$V8<-NULL

for(i in 1:length(final1[,5])) {
  audioFeaturesURL <- paste("https://api.genius.com/search?q=", 
                            final1[i,5], 
                            sep="")
  getaudioFeatures <- GET(audioFeaturesURL, add_headers(Authorization = HeaderValue))
  audioFeatures <- jsonlite::fromJSON(toJSON(content(getaudioFeatures)))
  answer <- unlist(audioFeatures$response$hits$result$url[1], use.names=FALSE)
  answer1 <- ifelse(is.null(answer), "No Lyrics", answer)
  answer2 <- unlist(audioFeatures$response$hits$result$primary_artist$id[1], use.names=FALSE)
  answer3 <- ifelse(is.null(answer2), "No Lyrics", answer2)
  final1[i,6] <- answer1
  final1[i,7] <- answer3
}

##ARTIST ID
for(i in 1:length(final1[,7])) {
  audioFeaturesURL <- paste("https://api.genius.com/artists/", 
                            final1[i,7], 
                            sep="")
  getaudioFeatures <- GET(audioFeaturesURL, add_headers(Authorization = HeaderValue))
  audioFeatures <- jsonlite::fromJSON(toJSON(content(getaudioFeatures)))
  answer <- unlist(audioFeatures$response$artist$twitter_name, use.names=FALSE)
  answer1 <- ifelse(is.null(answer), "No Twitter Name", answer)
  final1[i,8] <- answer1
}

final2<-select(final1, NAME, `ARTIST NAME`, V6, V8)
colnames(final2)[3] <- "Genius Lyrics Link"
final2$Without <- gsub("https://genius.com/","",final2$`Genius Lyrics Link`)
final2$Artist_First <- sub("-.*", "", final2$Without)
final2$Exists_In_URL <- mapply(grepl, pattern=final2$Artist_First, x=final2$`ARTIST NAME`)
final2$NewURL <- ifelse(final2$Exists_In_URL == TRUE, final2$`Genius Lyrics Link`, "No Lyrics")
final2 <- final2[!grepl("No Lyrics", final2$`NewURL`),]
##final2$NewURL <- paste0("<a href='",final2$NewURL,"' target='_blank'>",final2$NewURL,"</a>")
final2 <- select(final2, NAME, `ARTIST NAME`, NewURL, V8)
colnames(final2)[3] <- "Genius Lyrics Link"

##TWITTER

client_twitter_id <- "KxmCJDmGHiVmhgsDXu0Xx1Sv4"
client_twitter_secret <- "PiBV4GvJE3xDDWLmwT6IVKiCVuJS00hVF8MdmXoUUGd6BsHY41"

twitter_token <- "3346559890-NSSgoOv1djcSTEp24Ksw7AbhqdXms5ELbAdzb2K"

HeaderValue = paste0('Bearer ', twitter_token)


response = POST(
  'https://api.twitter.com/token',
  accept_json(),
  authenticate(client_twitter_id, client_twitter_secret),
  body = list(grant_type = 'client_credentials'),
  encode = 'form',
  verbose()
)

##token = content(response)$access_token
twitter_token <- "3346559890-NSSgoOv1djcSTEp24Ksw7AbhqdXms5ELbAdzb2K"
HeaderValue = paste0('Bearer ', twitter_token)




consumer_key <- "KxmCJDmGHiVmhgsDXu0Xx1Sv4"
consumer_secret <- "PiBV4GvJE3xDDWLmwT6IVKiCVuJS00hVF8MdmXoUUGd6BsHY41"
access_token <- "3346559890-NSSgoOv1djcSTEp24Ksw7AbhqdXms5ELbAdzb2K"
access_secret <- "YjFoU1dDeIl93cNb6jislPaCdlniwHaFVqg3n83VFIhLw"

setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

final2$Primary_Artist <- gsub(",.*$", "", final2$`ARTIST NAME`)
final2$Primary_Artist1 <- gsub(" ", " + ", final2$Primary_Artist, fixed=TRUE)
newdf1<-data.frame(unique(final2[,6]))
newdf2<-data.frame(unique(final2[,1]))
colnames(newdf2)[1]<-"Songs"
##DUMMY DATAFRAME
text = c("This is neutral") 
Col2 = 0
Col3 = 0
Col4 = 0
Col5 = 0
Col6 = 0
Col7 = 0
Col8 = 0
Col9 = 0
Col10 = 0
Col11 = 0
Col12 = 0
Col13 = 0
Col14 = 0
Col15 = 0
Col16 = 0
df = data.frame(text, Col2, Col3, Col4, Col5, Col6, Col7, Col8, Col9, Col10, Col11, Col12, Col13, Col14, Col15, Col16)

for(i in 1:length(newdf1[,1])) {
  newdf <- searchTwitter(as.character(newdf1[i,1]), n=1000)
  twitterdf <- if(length(newdf)==0) {df} else {twListToDF(newdf)}
  twitterdf <- select(twitterdf, text)
  twitterdf <- unique(twitterdf)
  twitterdf$filtered = gsub("&amp", "", twitterdf$text)
  twitterdf$filtered = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", twitterdf$filtered)
  twitterdf$filtered = gsub("@\\w+", "", twitterdf$filtered)
  twitterdf$filtered = gsub("[[:punct:]]", "", twitterdf$filtered)
  twitterdf$filtered = gsub("[[:digit:]]", "", twitterdf$filtered)
  twitterdf$filtered = gsub("http\\w+", "", twitterdf$filtered)
  twitterdf$filtered = gsub("[ \t]{2,}", "", twitterdf$filtered)
  twitterdf$filtered = gsub("^\\s+|\\s+$", "", twitterdf$filtered) 
  twitterdf$filtered <- sapply(twitterdf$filtered,function(row) iconv(row, "latin1", "ASCII", sub=""))
  
  twitterdf$filtered <- sapply(newdf2$Songs,function(w) twitterdf$filtered <<- gsub(paste0(w,"|",tolower(w)),"it",twitterdf$filtered))
  
  testing<-data.frame(twitterdf$filtered)
  testing1<-data.frame(testing[,ncol(testing)])
  colnames(testing1)[1]<-"Tweets"
  testing1$Tweets<-as.character(testing1$Tweets)
  testing1$sentiment1<-data.frame(get_sentiment(testing1[,1]))
  answer1<-mean(testing1$sentiment1$get_sentiment.testing1...1..)
  newdf1[i,2] <- answer1
}

withsentiment <- left_join(final2,newdf1,by=c("Primary_Artist1"="unique.final2...6.."))
sentiment_filtered <- select(withsentiment, NAME, `ARTIST NAME`, `Genius Lyrics Link`,V8, V2)
colnames(sentiment_filtered)[5] <- "Recent Twitter Sentiment"
colnames(sentiment_filtered)[4] <- "Twitter Name"
sentiment_filtered$`Recent Twitter Sentiment`<-as.numeric(sentiment_filtered$`Recent Twitter Sentiment`)
setwd("C:/Users/nickk/OneDrive/Documents/website/r-projects")
write_csv(sentiment_filtered,"testing.csv")
