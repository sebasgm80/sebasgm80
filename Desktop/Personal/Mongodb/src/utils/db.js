const dotenv = require('dotenv');
dotenv.config();

const {connect} = require("./src/utils/db");

const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI;

const connect = async () => {
    try {
        const db = await mongoose.connect(MONGO_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });

        const { name, host } = db.connection;
        console.log(`MongoDB connected: ${name} @ ${host}`);
    } catch (error) {
        console.error('Error connecting to MongoDB:', error.message);
    }
};

module.exports = { connect };

    
