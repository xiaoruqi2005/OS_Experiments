#ifndef __VIRTIO_H__
#define __VIRTIO_H__

#include "riscv.h"

#define VIRTIO0 0x10001000

// VirtIO MMIO 寄存器偏移
#define VIRTIO_MMIO_MAGIC_VALUE         0x000
#define VIRTIO_MMIO_VERSION             0x004
#define VIRTIO_MMIO_DEVICE_ID           0x008
#define VIRTIO_MMIO_VENDOR_ID           0x00c
#define VIRTIO_MMIO_DEVICE_FEATURES     0x010
#define VIRTIO_MMIO_DRIVER_FEATURES     0x020
#define VIRTIO_MMIO_GUEST_PAGE_SIZE     0x028 // Legacy
#define VIRTIO_MMIO_QUEUE_SEL           0x030
#define VIRTIO_MMIO_QUEUE_NUM_MAX       0x034
#define VIRTIO_MMIO_QUEUE_NUM           0x038
#define VIRTIO_MMIO_QUEUE_ALIGN         0x03c // Legacy
#define VIRTIO_MMIO_QUEUE_PFN           0x040 // Legacy: 物理页号
#define VIRTIO_MMIO_QUEUE_READY         0x044 // Modern
#define VIRTIO_MMIO_QUEUE_NOTIFY        0x050
#define VIRTIO_MMIO_INTERRUPT_STATUS    0x060
#define VIRTIO_MMIO_INTERRUPT_ACK       0x064
#define VIRTIO_MMIO_STATUS              0x070

// 描述符标志
#define VRING_DESC_F_NEXT  1
#define VRING_DESC_F_WRITE 2

// 描述符结构
struct virtq_desc {
    uint64 addr;
    uint32 len;
    uint16 flags;
    uint16 next;
};

// 可用环结构
struct virtq_avail {
    uint16 flags;
    uint16 idx;
    uint16 ring[8]; // NUM = 8
    uint16 unused;
};

// 已用环元素
struct virtq_used_elem {
    uint32 id;
    uint32 len;
};

// 已用环结构
struct virtq_used {
    uint16 flags;
    uint16 idx;
    struct virtq_used_elem ring[8]; // NUM = 8
};

#endif // __VIRTIO_H__
