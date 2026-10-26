#cloud-config

# Enable SSH with password auth
ssh_pwauth: true

# Install packages
packages:
  - curl
  - wget
  - git
  - htop
  - nano
  - vim
  - openssl
  - net-tools

# Create a group for each team
groups:
%{ for team in unique_teams ~}
  - ${team}
%{ endfor ~}

# Create users
users:
%{ for idx, user in all_users ~}
  - name: ${user.username}
    shell: /bin/bash
    sudo: ['ALL=(ALL) ALL']
    groups: ${user.team}
    lock_passwd: false
%{ endfor ~}

# SSH configuration in a separate file
write_files:
  - path: /etc/ssh/sshd_config.d/99-custom.conf
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      PermitRootLogin no
      UsePAM yes
    permissions: '0644'

# Setup commands
chpasswd:
  expire: false
  users:
%{ for idx, user in all_users ~}
    - name: ${user.username}
      password: "${passwords[idx]}"
      type: text
%{ endfor ~}

runcmd:
  - systemctl restart sshd
  
  # Optional: Firewall
  - ufw --force enable
  - ufw allow OpenSSH
  
  # Setup log (WITHOUT passwords for security reasons)
  - |
    cat >> /var/log/setup-complete.log <<EOF
    ================================================
    Setup abgeschlossen: $(date)
    ================================================
    Teams: ${join(", ", unique_teams)}
    Benutzer erstellt: ${length(all_users)}
    ================================================
    EOF

# Final message
final_message: |
  ================================================
  Ubuntu Multi-User System bereit!
  ================================================
  Teams: ${join(", ", unique_teams)}
  Benutzer: ${length(all_users)}
  
  SSH-Login: ssh <username>@<vm-ip>
  ================================================