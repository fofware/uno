var mongoose = require('mongoose');
var bcrypt = require('bcryptjs');

// User Schema
var LogDataSchema = mongoose.Schema({
	time: {
		type: String,
		index:true
	},
	controler: {
		type: String
	},
	email: {
		type: String
	},
	name: {
		type: String
	},
	account: {
		type: String
	}
});

var LogData = module.exports = mongoose.model('logdata', LogDataSchema);

module.exports.createLogData = function(newLogUser, callback){
	bcrypt.genSalt(10, function(err, salt) {
	    bcrypt.hash(newUser.password, salt, function(err, hash) {
	        newUser.password = hash;
	        newUser.save(callback);
	    });
	});
}

module.exports.getUserByUsername = function(username, callback){
	var query = {username: username};
	User.findOne(query, callback);
}

module.exports.getUserById = function(id, callback){
	User.findById(id, callback);
}

module.exports.comparePassword = function(candidatePassword, hash, callback){
	bcrypt.compare(candidatePassword, hash, function(err, isMatch) {
    	if(err) throw err;
    	callback(null, isMatch);
	});
}