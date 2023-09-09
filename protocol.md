All strings shall be null-terminated UTF-8. "$" is this document's chosen hexadecimal prefix. Bits are zero-indexed LSB first: $03 has bits 0 and 1 turned on and other bits turned off. All multi-byte integers are little-endian.


# Page 0 routines
- Each Page 0 routine is reserved at ($ff97 + original_address).
- These routines need not be populated with code.
- There's three machine cycles burned on all Page 0 routine calls because of being reached with a JR.

# Connection Establishment Protocol
- Client sends any byte.
- Host replies with any byte.
- Client sends "gb-dlp".
- Host replies with "gb-dlp".

# Version Negotiation Protocol
- Client sends bitmask of supported protocols.
    - Bit 0: on if client supports Protocol v1
    - Other bits: reserved
- Host sends byte numerically specifying which version among those versions it would like to use. For example, $01 for v1, or $05 for a hypothetical v5. If the host supports none of the versions in the bitmask, it replies with $00.
- If the host responds with a version that the client does not support, or the host responds with $00, the client responds with $ff and the connection is terminated. Otherwise, a response of $00 is sent and the host's chosen protocol is initiated.

# Protocol v1
## Protocol overview
- Client sends a system byte:
    - bit 0: on if client is GBC-compatible
    - bit 1: on if client is GBC-compatible and on GBA
    - bit 2: on if client is SGB-compatible
- Host sends $00 if the platform is supported, or any other value otherwise. If the response is not $00, the client responds with $ff and the connection is terminated.
- The client's LCD turns off (and stays off into handoff) so data can be sent to VRAM.
- When the client is ready, it sends any byte.
- The host first sends the address to jump to when finished receiving segments.
- The host then sends segments (see format below).
- A segment of size $0000 is the last segment.
- Addresses $ff01-$ff02 (serial data and control), $ff0f (IF), $ff95-$ff96 (stack word), and $ffff (IE) must not be modified until after handoff.
- Do not write to cart-mapped addresses.

## Segment format
- 2 bytes: start address
- 2 bytes: length
- (length) bytes: data

## Handoff state
All state not specified and not sent by segments must not be depended upon.
- IME: Off
- IE: $08
- HL and PC: Specified entrypoint
- LCD is off unless turned on by segment
- SGB multiplayer is disabled unless turned on by segment
- Timer state should not be depended upon
