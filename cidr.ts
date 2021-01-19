const ipaddress = require('ip-address');
const { BigInteger } = require('jsbn');

// Takes an IP address range in CIDR notation (like 10.0.0.0/8) and extends its prefix to include an additional subnet number.
// For example:
// * cidrsubnet("10.0.0.0/8", 8, 2) returns 10.2.0.0/16
// * cidrsubnet("2607:f298:6051:516c::/64", 8, 2) returns 2607:f298:6051:516c:200::/72
exports.cidrSubnet = function (
  iprange: string,
  newbits: number,
  netnum: number
) {
  var ipv4 = new ipaddress.Address4(iprange);
  var ipv6 = new ipaddress.Address6(iprange);
  if (ipv4.isValid()) {
    const newsubnetMask = ipv4.subnetMask + newbits;
    if (newsubnetMask > 32) {
      throw new Error(
        'Requested ' +
          newbits +
          ' new bits, but only ' +
          (32 - ipv4.subnetMask) +
          ' are available.'
      );
    }
    var addressBI = ipv4.bigInteger();
    var twoBI = new BigInteger('2');
    var netnumBI = new BigInteger(netnum.toString());

    var newAddresBI = addressBI.add(
      twoBI.pow(32 - newsubnetMask).multiply(netnumBI)
    );
    var newAddress = ipaddress.Address4.fromBigInteger(newAddresBI).address;

    return newAddress + '/' + newsubnetMask;
  } else if (ipv6.isValid()) {
    const newsubnetMask = ipv6.subnetMask + newbits;
    if (newsubnetMask > 128) {
      throw new Error(
        'Requested ' +
          newbits +
          ' new bits, but only ' +
          (128 - ipv6.subnetMask) +
          ' are available.'
      );
    }
    var addressBI = ipv6.bigInteger();
    var twoBI = new BigInteger('2');
    var netnumBI = new BigInteger(netnum.toString());

    var newAddresBI = addressBI.add(
      twoBI.pow(128 - newsubnetMask).multiply(netnumBI)
    );
    var newAddress = ipaddress.Address6.fromBigInteger(
      newAddresBI
    ).correctForm();

    return newAddress + '/' + newsubnetMask;
  } else {
    throw new Error('Invalid IP address range: ' + iprange);
  }
};

// Takes an IP address range in CIDR notation and creates an IP address with the given host number.
// If given host number is negative, the count starts from the end of the range.
// For example:
// * cidrhost("10.0.0.0/8", 2) returns 10.0.0.2
// * cidrhost("10.0.0.0/8", -2) returns 10.255.255.254
exports.cidrHost = function (iprange: string, hostnum: number) {
  var ipv4 = new ipaddress.Address4(iprange);
  var ipv6 = new ipaddress.Address6(iprange);
  if (ipv4.isValid()) {
    var hostnumBI = new BigInteger(hostnum.toString());
    var addressBI;
    if (hostnum >= 0) {
      var startAddressBI = ipv4.startAddress().bigInteger();
      addressBI = startAddressBI.add(hostnumBI);
    } else {
      var endAddressBI = ipv4.endAddress().bigInteger();
      addressBI = endAddressBI.add(hostnumBI).add(new BigInteger('1'));
    }
    return ipaddress.Address4.fromBigInteger(addressBI).address;
  } else if (ipv6.isValid()) {
    return null;
  } else {
    throw new Error('Invalid IP address range: ' + iprange);
  }
};
