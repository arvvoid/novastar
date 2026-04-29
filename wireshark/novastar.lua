-- local folderOfThisFile = debug.getinfo(1).source:match("@?(.*/)")
-- local addresses = require(folderOfThisFile .. "/addressMapping")
local source = debug.getinfo(1).source
local folderOfThisFile = source:match("@?(.+[\\/])") or ""

package.path = folderOfThisFile .. "?.lua;" .. package.path
local addresses = require("addressMapping")

-- List of TCP ports used by the Novastar protocol.
-- You can easily add or remove ports here.
local NOVASTAR_PORTS = {
    5200,
    5201,
    5203,
}

NOVASTAR_PROTO = Proto ("novastar", "Novastar Protocol")

local f_head = ProtoField.uint16("novastar.head", "Header", base.HEX, {[0xaa55] = "Request", [0x55aa] = "Response" })
local f_ack = ProtoField.uint8("novastar.ack", "Status", base.DEC, {
  [0] = "Success",
  [1] = "Timeout Error",
  [2] = "Request CRC Error",
  [3] = "Response CRC Error",
  [4] = "Unknown Command",
  [255] = "Invalid"
})
local ef_timeout = ProtoExpert.new("novastar.timeout.expert", "Timeout Error",
    expert.group.RESPONSE_CODE,
    expert.severity.ERROR);

local ef_request = ProtoExpert.new("novastar.request.expert", "Request Error",
    expert.group.RESPONSE_CODE,
    expert.severity.ERROR);

local ef_response = ProtoExpert.new("novastar.acknowledge.expert", "Acknowledge Error",
    expert.group.RESPONSE_CODE,
    expert.severity.ERROR);

local ef_invalid = ProtoExpert.new("novastar.invalid.expert", "Invalid Command",
    expert.group.RESPONSE_CODE,
    expert.severity.ERROR);


local f_serno = ProtoField.uint8("novastar.serno", "Index", base.DEC)
local f_source = ProtoField.uint8("novastar.source", "Source", base.HEX, {[0xfe] = "Computer", [0] = "Device"})
local f_destination = ProtoField.uint8("novastar.destination", "Destination", base.HEX, {[0xfe] = "Computer", [0] = "Device"})
local f_deviceType = ProtoField.uint8("novastar.deviceType", "Device Type", base.DEC, {
  [0] = "SendingCard",
  [1] = "ReceivingCard",
  [2] = "FunctionCard"
})
local f_port = ProtoField.uint8("novastar.port", "Port", base.DEC)
local f_rcvIndex = ProtoField.uint16("novastar.rcvIndex", "Receiving Card Index", base.DEC)
local f_io = ProtoField.uint8("novastar.io", "Dir", base.DEC, { [0] = "Read", [1] = "Write" })
local f_address = ProtoField.uint32("novastar.address", "Address", base.HEX, addresses)
local f_length = ProtoField.uint16("novastar.length", "Length", base.HEX_DEC)
local f_data = ProtoField.bytes("novastar.data", "Data", base.DASH)
local f_crc = ProtoField.uint16("novastar.crc", "CRC", base.HEX)

NOVASTAR_PROTO.fields = {
    f_head,
    f_ack,
    f_serno,
    f_source,
    f_destination,
    f_deviceType,
    f_port,
    f_rcvIndex,
    f_io,
    f_address,
    f_length,
    f_data,
    f_crc,
}

NOVASTAR_PROTO.experts = { ef_timeout, ef_request, ef_response, ef_invalid }
local experts = { [1] = ef_timeout, [2] = ef_request, [3] = ef_response, [4] = ef_invalid, [255] = ef_invalid }

function NOVASTAR_PROTO.dissector (buf, pinfo, tree)
  if buf:len() < 20 then
    pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
    pinfo.desegment_offset = 0
    return
  end

  local header = buf(0, 2):le_uint()
  if header ~= 0x55aa and header ~= 0xaa55 then
    return 0
  end

  local io = buf(10, 1):uint()
  local length = buf(16, 2):le_uint()

  local expected_packet_len = 20
  if length > 0 and ((header == 0x55aa and io == 0) or (header == 0xaa55 and io == 1)) then
    expected_packet_len = 20 + length
  end

  if buf:len() < expected_packet_len then
    pinfo.desegment_len = expected_packet_len - buf:len()
    pinfo.desegment_offset = 0
    return
  end

  local pktbuf = buf(0, expected_packet_len)
  
  pinfo.cols.protocol = NOVASTAR_PROTO.name
  pinfo.cols.info:clear()
  if header == 0xaa55 then
    pinfo.cols.info:append("Request")
  else
    pinfo.cols.info:append("Response")
  end

  local subtree = tree:add(NOVASTAR_PROTO, pktbuf)
  subtree:add_le(f_head, pktbuf(0, 2))
  
  if (header == 0x55aa) then
    local ack = pktbuf(2, 1):uint()
    subtree:add(f_ack, pktbuf(2, 1))
    if experts[ack] then
      subtree:add_proto_expert_info(experts[ack])
    end
  end
  
  subtree:add(f_serno, pktbuf(3, 1))
  subtree:add(f_source, pktbuf(4, 1))
  subtree:add(f_destination, pktbuf(5, 1))
  subtree:add(f_deviceType, pktbuf(6, 1))
  subtree:add(f_port, pktbuf(7, 1))
  subtree:add_le(f_rcvIndex, pktbuf(8, 2))
  subtree:add(f_io, pktbuf(10, 1))
  
  local address = pktbuf(12, 4):le_uint()
  subtree:add_le(f_address, pktbuf(12, 4))
  pinfo.cols.info:append(string.format(" Addr: 0x%08X", address))

  local offset = 18
  if length > 0 then
    subtree:add_le(f_length, pktbuf(16, 2))
    if expected_packet_len > 20 then
      subtree:add(f_data, pktbuf(offset, length))
      offset = offset + length
    end
  end
  subtree:add_le(f_crc, pktbuf(offset, 2))
  
  return expected_packet_len
end

local tcp_dissector_table = DissectorTable.get("tcp.port")
for _, port in ipairs(NOVASTAR_PORTS) do
  tcp_dissector_table:add(port, NOVASTAR_PROTO)
end
