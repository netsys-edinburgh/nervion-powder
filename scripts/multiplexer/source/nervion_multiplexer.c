#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include "hashmap.h"
#include "log.h"

#define MULTIPLEXER_PORT 2154
#define CORE_PORT 2152
#define BUFFER_LEN 65536
#define HASHMAP_SIZE 8192

typedef struct _Data {
    struct sockaddr_in ue_addr;
    uint32_t teid;
    int ue_len;
} Data;


uint32_t data_hash(void * data)
{
    Data * d = (Data *) data;
    return d->teid;
}

void dump(uint8_t * pointer, int len)
{
    int i;
    for(i = 0; i < len; i++)
    {
        if(i % 16 == 0 && i > 0)
            printf("\n");
        else if(i % 8 == 0)
            printf("  ");
        printf("%.2x ", pointer[i]);
    }
    printf("\n");
}


/* Global variables */
int ran_sock;
int core_sock;
struct sockaddr_in coreaddr, multi_ran_addr, multi_core_addr;
HashMap * map;

uint32_t get_ue_teid(uint8_t * buffer)
{
    return (buffer[4] << 24) | (buffer[5] << 16) | (buffer[6] << 8) | buffer[7];
}

void * uplink(void * args)
{
    uint8_t buffer[BUFFER_LEN];
    struct sockaddr_in ue_addr;
    int n;
    int ue_len = sizeof(ue_addr);
    int core_len = sizeof(coreaddr);
    Data data;

    printInfo("Starting Uplink thread...\n");

    while(1)
    {
        /* Receive UE message */
        n = recvfrom(ran_sock, (char *)buffer, BUFFER_LEN, 0, ( struct sockaddr *) &ue_addr, (socklen_t *) &ue_len);
        if(n < 0)
        {
            printError("Uplink read error: %s\n", strerror(errno));
            close(ran_sock);
            return NULL;
        }
        /* Assemble Data structure */
        memset(&data, 0, sizeof(Data));
        memcpy(&(data.ue_addr), &ue_addr, ue_len);
        data.teid = get_ue_teid(buffer);
        data.ue_len = ue_len;

        /* Save UE address in the hashmap structure */
        if(hashmap_add(map, (uint8_t *) &data, sizeof(Data)) == ERROR)
        {
            printError("Error adding UE address to the hashmap\n");
        }

        /* Forward packet to SPGW/UPF */
        sendto(core_sock, buffer, n, 0, (const struct sockaddr *) &coreaddr, (socklen_t) core_len);
    }
    return NULL;
}

void * downlink(void * args)
{
    uint8_t buffer[BUFFER_LEN];
    int n;
    int core_len = sizeof(coreaddr);
    Data * data;

    printInfo("Starting Downlink thread...\n");

    while(1)
    {
        /* Receive SPGW/UPF message */
        n = recvfrom(core_sock, (char *)buffer, BUFFER_LEN, 0, ( struct sockaddr *) &coreaddr, (socklen_t *) &core_len);
        if(n < 0)
        {
            printError("Downlink read error: %s\n", strerror(errno));
            close(core_sock);
            return NULL;
        }

        /* Get UE address based on the TEID */
        data = (Data *) hashmap_get(map, get_ue_teid(buffer));

        /* Forward packet to the UE */
        sendto(ran_sock, buffer, n, 0, (const struct sockaddr *) &(data->ue_addr), (socklen_t) data->ue_len);
    }
    return NULL;
}

int main(int argc, char const *argv[])
{
    pthread_t uplink_thread, downlink_thread;

    if(argc != 3)
    {
        printError("USAGE: ./nervion_multiplexer <Multiplexer IP> <SPGW/UPF IP>\n");
        return 1;
    }

    /* Filling Multiplexer (RAN and Core) addresses */
    /* Multiplexer RAN address (2152) */
    multi_ran_addr.sin_family = AF_INET;
    multi_ran_addr.sin_addr.s_addr = inet_addr(argv[1]);
    multi_ran_addr.sin_port = htons(MULTIPLEXER_PORT);
    memset(&(multi_ran_addr.sin_zero), '\0', 8);
    /* Multiplexer Core address (2154) */
    multi_core_addr.sin_family = AF_INET;
    multi_core_addr.sin_addr.s_addr = inet_addr(argv[1]);
    multi_core_addr.sin_port = htons(CORE_PORT);
    memset(&(multi_core_addr.sin_zero), '\0', 8);

    if(multi_core_addr.sin_addr.s_addr == (in_addr_t)(-1))
    {
        printError("Invalid Multiplexer IP address\n");
        return 1;
    }

    /* Filling Core address */
    coreaddr.sin_family = AF_INET;
    coreaddr.sin_addr.s_addr = inet_addr(argv[2]);
    coreaddr.sin_port = htons(CORE_PORT);
    memset(&(coreaddr.sin_zero), '\0', 8);

    if(coreaddr.sin_addr.s_addr == (in_addr_t)(-1))
    {
        printError("Invalid SPGW/UPF IP address\n");
        return 1;
    }

    /* Creating Uplink socket */
    if ( (ran_sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) {
        printError("Error creating uplink socket: %s\n", strerror(errno));
        return 1;
    }

    /* Creating Downlink socket */
    if ( (core_sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) {
        printError("Error creating downlink socket: %s\n", strerror(errno));
        close(ran_sock);
        return 1;
    }

    /* Binding RAN socket to Multiplexer RAN address */
    if(bind(ran_sock, (const struct sockaddr *)&multi_ran_addr, sizeof(multi_ran_addr)) < 0)
    {
        printError("Error binding uplink socket: %s\n", strerror(errno));
        close(ran_sock);
        close(core_sock);
        return 1;
    }

    /* Binding core socket to Multiplexer Core address */
    if(bind(core_sock, (const struct sockaddr *)&multi_core_addr, sizeof(multi_core_addr)) < 0)
    {
        printError("Error binding uplink socket: %s\n", strerror(errno));
        close(ran_sock);
        close(core_sock);
        return 1;
    }

    /* Instantiate hashmap structure */
    map = init_hashmap(HASHMAP_SIZE, data_hash);

    /* Creating uplink thread */
    if (pthread_create(&uplink_thread, NULL, uplink, 0) != 0)
    {
        printError("Error creating uplink thread: %s\n", strerror(errno));
        close(ran_sock);
        close(core_sock);
        return 1;
    }

    /* Creating downlink thread */
    if (pthread_create(&downlink_thread, NULL, downlink, 0) != 0)
    {
        printError("Error creating downlink thread: %s\n", strerror(errno));
        close(ran_sock);
        close(core_sock);
        return 1;
    }

    pthread_join(uplink_thread, NULL);
    pthread_join(downlink_thread, NULL);

    return 0;
}