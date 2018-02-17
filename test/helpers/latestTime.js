// original: https://github.com/Blockchainpartner/emindhub-crowdsale/blob/master/test/helpers/latestTime.js

// Returns the time of the last mined block in seconds
export default function latestTime() {
    return web3.eth.getBlock('latest').timestamp;
}
