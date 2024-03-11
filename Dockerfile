FROM ruby:2.5
LABEL authors="Yinlin Chen <ylchen@vt.edu>, Lee Hunter <whunter@vt.edu>"
WORKDIR /usr/local/iiif
RUN apt-get update && apt-get install -y imagemagick awscli && rm -rf /var/lib/apt/lists/*
RUN gem install --no-user-install --no-document --verbose iiif_s3
COPY policy.xml /etc/ImageMagick-6/policy.xml

COPY . .
CMD ["/usr/local/iiif/createiiif.sh"]
