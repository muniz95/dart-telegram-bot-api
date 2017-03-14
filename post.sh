#!/bin/bash

/usr/bin/curl -F "chat_id=$1" -F "audio=@$2" $3