const AWS = require('aws-sdk');

const s3 = new AWS.S3();
const bucketName = "bucket-name";


exports.handler = async (event) => {
    console.log(event);
    try {

        const path = event.path;

        if (path?.startsWith('/healthcheck')) {
            return {
                statusCode: 200
            };
        }

        if (!path?.startsWith('/public/') && !path?.startsWith('/.well-known/')) {
            console.log(`The path '${path}' is not supported`);
            return {
                statusCode: 404
            };
        }

        let params = {
            Bucket: bucketName,
            Key: path.substring(1)
        }
        console.log(`Requesting key ${path.substring(1)}...`);

        let data = await s3.getObject(params).promise();

        console.log(data);

        return returnResponse(path, data);

    } catch (err) {
        console.error(err);
        return {
            statusCode: 404
        };
    }
};


function returnResponse(path, data) {
    return {
        statusCode: 200,
        headers: { 'Content-Type': data.ContentType },
        body: data.Body.toString('base64'),
        isBase64Encoded: true
    };
}

