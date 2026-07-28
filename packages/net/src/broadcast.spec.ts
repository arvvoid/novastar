import { getBroadcastAddress } from './broadcast';

describe('getBroadcastAddress', () => {
  test.each([
    ['192.168.0.100', '255.255.255.0', '192.168.0.255'],
    ['192.168.23.24', '255.255.255.0', '192.168.23.255'],
    ['10.20.30.40', '255.255.240.0', '10.20.31.255'],
    ['172.16.1.2', '255.255.0.0', '172.16.255.255'],
    ['100.64.1.8', '255.255.255.255', '100.64.1.8'],
  ])('%s with netmask %s uses %s', (address, netmask, expected) => {
    expect(getBroadcastAddress(address, netmask)).toBe(expected);
  });

  test.each(['192.168.0', '192.168.0.256', 'not-an-address'])(
    'rejects invalid IPv4 address %s',
    (address) => {
      expect(() => getBroadcastAddress(address, '255.255.255.0')).toThrow('Invalid IPv4 address');
    },
  );
});
