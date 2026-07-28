const ipv4ToUint32 = (address: string): number => {
  const octets = address.split('.').map(Number);
  if (
    octets.length !== 4 ||
    octets.some((octet) => !Number.isInteger(octet) || octet < 0 || octet > 255)
  ) {
    throw new Error(`Invalid IPv4 address: ${address}`);
  }
  return octets.reduce((result, octet) => (result << 8) | octet, 0) >>> 0;
};

export const getBroadcastAddress = (address: string, netmask: string): string => {
  const broadcast = (ipv4ToUint32(address) | ~ipv4ToUint32(netmask)) >>> 0;
  return [24, 16, 8, 0].map((shift) => (broadcast >>> shift) & 0xff).join('.');
};
