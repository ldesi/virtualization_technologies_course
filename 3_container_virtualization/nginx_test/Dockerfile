FROM nginx:latest
RUN apt-get update && apt-get install -y net-tools
COPY edit_index.sh /usr/local/edit_index.sh 
ENTRYPOINT ["/usr/local/edit_index.sh"]
CMD ["nginx", "-g", "daemon off;"]

