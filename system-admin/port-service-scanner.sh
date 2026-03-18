#!/usr/bin/env bash
# port-service-scanner.sh — Show all listening ports with service identification
# Usage: sudo ./port-service-scanner.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Identify common ports
identify_port() {
    local port="$1"
    case "${port}" in
        # Remote access
        22)    echo "SSH" ;;
        23)    echo "Telnet" ;;
        3389)  echo "RDP" ;;
        # Web
        80)    echo "HTTP" ;;
        443)   echo "HTTPS" ;;
        8080)  echo "HTTP-Alt" ;;
        8443)  echo "HTTPS-Alt" ;;
        # Email
        25)    echo "SMTP" ;;
        587)   echo "SMTP-TLS" ;;
        993)   echo "IMAP-SSL" ;;
        # DNS & networking
        53)    echo "DNS" ;;
        67)    echo "DHCP" ;;
        123)   echo "NTP" ;;
        # Databases
        3306)  echo "MySQL" ;;
        5432)  echo "PostgreSQL" ;;
        1433)  echo "MSSQL" ;;
        1521)  echo "Oracle" ;;
        6379)  echo "Redis" ;;
        27017) echo "MongoDB" ;;
        9200)  echo "Elasticsearch" ;;
        5984)  echo "CouchDB" ;;
        # Message queues
        5672)  echo "RabbitMQ" ;;
        9092)  echo "Kafka" ;;
        4222)  echo "NATS" ;;
        # Containers & orchestration
        2375)  echo "Docker-API" ;;
        2376)  echo "Docker-TLS" ;;
        6443)  echo "K8s-API" ;;
        10250) echo "Kubelet" ;;
        10251) echo "K8s-Scheduler" ;;
        10252) echo "K8s-Controller" ;;
        2379)  echo "etcd-Client" ;;
        2380)  echo "etcd-Peer" ;;
        # Monitoring & logging
        9090)  echo "Prometheus" ;;
        3000)  echo "Grafana" ;;
        9100)  echo "Node-Exporter" ;;
        5601)  echo "Kibana" ;;
        5044)  echo "Logstash" ;;
        8086)  echo "InfluxDB" ;;
        # CI/CD & tools
        8081)  echo "Nexus/Jenkins" ;;
        9000)  echo "SonarQube" ;;
        8200)  echo "Vault" ;;
        8500)  echo "Consul" ;;
        # Proxy & load balancing
        8404)  echo "HAProxy-Stats" ;;
        # File sharing & directory
        389)   echo "LDAP" ;;
        636)   echo "LDAPS" ;;
        445)   echo "SMB" ;;
        111)   echo "NFS-RPC" ;;
        2049)  echo "NFS" ;;
        *)     echo "" ;;
    esac
}

section "SUMMARY"
# Count total unique listening ports (requires sudo for process info)
total=$(sudo ss -tlnp | tail -n +2 | awk '{print $4}' | rev | cut -d: -f1 | rev | sort -un | wc -l)
echo "Total unique listening TCP ports: ${total}"

section "LISTENING PORTS"
# Parse each listening port, remove duplicates, show details
sudo ss -tlnp | tail -n +2 | while read -r line; do
    # Extract address and port
    addr=$(echo "${line}" | awk '{print $4}')
    port=$(echo "${addr}" | rev | cut -d: -f1 | rev)
    # Extract process name from users:(("name",pid=123,fd=4))
    process=$(echo "${line}" | grep -oP '"\K[^"]+' | head -1)
    known=$(identify_port "${port}")

    if [[ -n "${known}" ]]; then
        echo "[${known}]  port ${port}  (${process})"
    else
        echo "[UNKNOWN]  port ${port}  (${process})"
    fi
done | sort -t't' -k2 -un
