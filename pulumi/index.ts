import * as pulumi from "@pulumi/pulumi";
import * as hcloud from "@pulumi/hcloud";
import * as fs from "fs";
import * as path from "path";

// Configuration
const config = new pulumi.Config();
const serverType = config.get("serverType") || "cpx11"; // 1 vCPU, 2 GB RAM
const location = config.get("location") || "fsn1";     // Falkenstein
const image = config.get("image") || "docker-ce";
const sshKeys = config.getObject<string[]>("sshKeys") || [];

// Read cloud-init template
const cloudInit = fs.readFileSync(
    path.join(__dirname, "../build/cloud-init.yaml"),
    "utf8"
);

// Create SSH key resources for each provided key
const sshKeyResources = sshKeys.map((keyData, index) => {
    return new hcloud.SshKey(`ssh-key-${index}`, {
        publicKey: keyData,
        name: `supreme-computing-key-${index}`,
    });
});

// Create a volume for backups first
const volume = new hcloud.Volume("backup-volume", {
    size: 10,
    location: location,
    name: "scm-backup",
});

// Create a new server
const server = new hcloud.Server("supreme-computing", {
    serverType: serverType,
    image: image,
    location: location,
    sshKeys: sshKeyResources.map(key => key.id),
    userData: cloudInit,
});

// Wait for both resources and then attach volume
server.id.apply(serverId => {
    volume.id.apply(volumeId => {
        return new hcloud.VolumeAttachment("backup-volume-attachment", {
            volumeId: Number(volumeId),
            serverId: Number(serverId),
            automount: true,
        }, { dependsOn: [server, volume] });
    });
});

// Export useful information
export const serverIp = server.ipv4Address;
export const serverStatus = server.status;
