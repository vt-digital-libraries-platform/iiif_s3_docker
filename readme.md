# IIIF_S3 docker image

This docker image is based on [iiif_s3](https://github.com/cmoa/iiif_s3)
Many, many thanks.

Image hosted at: [wlhunter/iiif_s3_tiling](https://hub.docker.com/repository/docker/wlhunter/iiif_s3_tiling)

## Getting Started

- Build the docker image

```
docker buildx build -t="docker_image" --platform linux/amd64 .
```

- Run the container

  - Required Environment variables

    - AWS_ACCESS_KEY_ID: AWS access key (not to be included in env.list . See note below)
    - AWS_SECRET_ACCESS_KEY: AWS secret access key (not to be included in env.list . See note below)
    - AWS_REGION: AWS region, e.g. us-east-1
    - COLLECTION_IDENTIFIER: identifier of collection that materials belong to
    - ACCESS_DIR: Path to the image folder to be processed
    - AWS_SRC_BUCKET: s3 bucket where source images to be processed are located
    - AWS_DEST_BUCKET: s3 target bucket where generated tiles should be written
    - DEST_PREFIX: Target folder inside the S3 bucket (AWS_DEST_BUCKET)
    - DEST_URL: Root URL for accessing the manifests e.g. https://s3.amazonaws.com/iiif-example
    - CSV_PATH: Path to the metadata csv that describes the materials to be tiled
    - CSV_NAME: A [CSV file](examples/example_archive_metadata.csv) with title and description of the images

  - Enviornment variables can be set in an env file and passed into the container as it's created. Example env file here: [env.list.example](env.list.example). Copy it as `env.list`, enter the values for your project, and pass it into the container:

```
docker run --env-file ./env.list -it -v mount_path:container_path docker_image
```

Note: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY should not be added to your env.list file but passed in as individual environment variables or mounted as a volume.

```
docker run -e AWS_ACCESS_KEY_ID=your_id -e AWS_SECRET_ACCESS_KEY=your_secret_key --env-file ./env.list -it -v mount_path:container_path docker_image
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/VTUL/iiif_s3_docker/tags).

## Authors

- Digital Libraries Development developers

See also the list of [contributors](https://github.com/VTUL/iiif_s3_docker/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

- [iiif_s3](https://github.com/cmoa/iiif_s3)
- [image-iiif-s3](https://github.com/VTUL/image-iiif-s3)
