'use strict';

// NOTE: once this script is executed, an update will be rolled out AUTOMATICALLY
// However, in order for this to succeed, it needs all the artifacts uploaded to S3; S3 upload is atomic and artifacts will only be uploaded if they pass CI tests, so this is safe to run 
// Recommended flow is: 1) Create and push tag ; 2) Once CI builds have passed, test the artifacts ; 3) Run this script

var gulp = require('gulp')
var path = require('path')
var crypto = require('crypto')
var async = require('async')
var AWS = require('aws-sdk')
var fs = require('fs')
var child = require('child_process')

var pathToPrivateKey = process.env.PRIV_KEY
var defaultPrivateKey = path.join(process.env.HOME || process.env.USERPROFILE, 'OneDrive', 'stremio4Release.pem')
var releaseTag = process.env.TAG;
var IS_BETA = process.env.IS_BETA;
var BASE = 'https://dl.strem.io'

var BUCKET = 'stremio-artifacts'
var keyPrefix = IS_BETA ? 'versions/beta/' : 'versions/';

gulp.task('release-version', function(cb) {
	if (! pathToPrivateKey) {
		console.log('no PRIV_KEY passed, assuming '+defaultPrivateKey)
		pathToPrivateKey = defaultPrivateKey
	}

	if (! fs.existsSync(pathToPrivateKey)) {
		console.log('private key '+pathToPrivateKey+' not found')
		cb(new Error('private key not found'))
		return
	}

	if (! process.env.PRIV_KEY_PASS) {
		cb(new Error('no PRIV_KEY_PASS'))
		return
	}

	var tag = process.env.TAG
	if (! tag) {
		cb(new Error('no TAG'))
		return
	}

	if (! (process.env.AWS_KEY || process.env.AWS_SECRET)) {
		cb(new Error('no AWS_KEY/AWS_SECRET'))
		return
	}

	var s3 = new AWS.S3({ region: 'eu-west-1', accessKeyId: process.env.AWS_KEY, secretAccessKey: process.env.AWS_SECRET });
	s3.getObject({ Bucket: BUCKET, Key: keyPrefix+tag+'.json' }, function(err, obj) {
		if (err && err.code!='NoSuchKey') return cb(err)
		if (!process.env.FORCE && obj) return cb('version '+tag+' already exists; pass FORCE=1 to re-generate version descriptor')

		getVersions(tag, function(err, versions) {
			if (err) return cb(err)

			if (! process.env.CONFIRM) {
				console.log("About to upload a version descriptor generated from versions", versions)
				console.log("Please pass CONFIRM=1 to really do it")
				process.exit(1)
			}

			putVersionTag(s3, versions, cb)
		})
	})
})


function putVersionTag(s3, versions, cb) {
	var tag = versions.tag;
	var versionDesc = {
		version: tag.slice(1),
		tag: tag,
		serverVersion: versions.server,
		shellVersion: versions.shell,
		shellRevision: versions.shellRevision,
		released: new Date(),
		files: { } // to be filled
	}

	var files = {
		'server.js': 'four/'+tag+'/server.js',
		'stremio.asar': 'four/'+tag+'/stremio.asar',
		'windows': 'shell-win/'+tag+'/Stremio '+tag.slice(1)+'.exe',
		'mac': 'shell-osx/'+tag+'/Stremio '+tag.slice(1)+'.dmg',
		//'linux': 'linux/'+tag+'/Stremio '+tag.slice(1)+'.appimage',
	}

	async.eachSeries(Object.keys(files), function(file, cb) {
		console.log('Downloading: '+files[file])

		var params = { Bucket: BUCKET, Key: files[file] };

		var hash = crypto.createHash('sha256')

		s3.getObject(params).createReadStream()
		.on('error', cb)
		.on('data', function(d) { hash.update(d) })
		.on('end', function() {
			versionDesc.files[file] = {
				url: BASE+'/'+files[file].replace(' ', '+'),
				checksum: hash.digest('hex'),
			}
			cb()
		})

	}, function(err) {
		if (err) return cb(err)

		// Prepare the version descriptor
		var versionDescJSON = JSON.stringify(versionDesc)

		// Sign the version descriptor
		var sign = crypto.createSign('RSA-SHA256')
		sign.write(versionDescJSON)
		sign.end()

		var signature = sign.sign({
			key: fs.readFileSync(pathToPrivateKey),
			passphrase: process.env.PRIV_KEY_PASS
		}, 'base64')

		// Upload signature, and then descriptor itself
		s3.putObject({
			Bucket: BUCKET, Key: keyPrefix+tag+'.json.sig',
			Body: signature,
			ACL: 'public-read', CacheControl: 'maxage=43200'
		}, function(err) {
			if (err) return cb(err)

			s3.putObject({ 
				Bucket: BUCKET, Key: keyPrefix+tag+'.json',
				Body: versionDescJSON,
				ACL: 'public-read',
				CacheControl: 'maxage=43200', // 12 * 60 * 60
			}, function(err) {
				if (err) return cb(err)

				cb()
			})
		})
	})
}

var yarnVerRegex = /"stremio-server@.*\n.*version "((\d+\.)?(\d+\.)?(\*|\d+))"/
var shellCommitRegex = /commit ([0-9a-f]{40})/;
var shellVerRegex = /VERSION=((\d+\.)?(\d+\.)?(\*|\d+))/ // matched directly in stremio.pro; now we use the submodule hash to match against a ver

function getVersions(tag, cb) {
	var appVersion = tag.slice(1).split('-')[0]
	var versions = { tag: tag }
	getShellVer(tag, function(err, shell) {
		if (err) return cb(err)

		versions.shell = shell

		if (appVersion != versions.shell)
			return cb(new Error('app version '+appVersion+' mismatches shell version '+versions.shell+'; when releasing, those versions should match'))

		matchFromCmd('git show '+tag+':'+'yarn.lock', yarnVerRegex, 'serverVersion', function(err, server) {
			if (err) return cb(err)

			versions.server = server

			cb(null, versions)
		})
	})
}

function getShellVer(tag, cb) {
	matchFromCmd('git ls-tree '+tag+' shell', shellCommitRegex, 'getShellCommit', function(err, commit) {
		if (err) return cb(err)

		matchFromCmd('( cd shell ; git show '+commit+':stremio.pro )', shellVerRegex, 'getShellVer', function(err, version) {
			if (err) return cb(err)

			matchFromCmd('(cd shell ; git describe --tags '+commit+')', /(.*)/, 'getShellTag', function(err, tag) {
				if (err) return cb(err)

				if (!(version === tag || 'v'+version === tag))
					return cb(new Error('shell tag '+tag+' (commit '+commit+') mismatches version in stremio.pro file '+version))

				cb(null, version)
			})
		})
	})
}

function matchFromCmd(cmd, regex, errString, cb) {
	child.exec(cmd, { maxBuffer: 1024 * 500 }, function(err, stdout, stderr) {
		if (err) return cb(err)
		if (stderr) return cb(stderr)
		var match = stdout.match(regex)
		if (match) cb(null, match[1])
		else cb(new Error('unable to identify '+errString))
	})
}
