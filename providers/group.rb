action :join do
  host_key = ::File.read("/etc/ssh/ssh_host_rsa_key.pub").strip
  if host_key != node["dsh"]["host_key"]
    node["dsh"]["host_key"] = host_key
    new_resource.updated_by_last_action(true)
  end
  if new_resource.user and current_resource and 
      new_resource.user != current_resource.user
    node["dsh"]["groups"][new_resource.name] = current_resource.user
    new_resource.updated_by_last_action(true)
  end
  if new_resource.admin_user
    home = ::File.expand_path "~#{new_resource.admin_user}"
    privkey_path = "#{home}/.ssh/id_rsa"
    pubkey_path = "#{privkey_path}.pub"
    if not (::File.exists? privkey_path or ::File.exists? pubkey_path)
      #generate ssh key
      system("ssh-keygen -q -f #{privkey_path} -P \"\"", :in=>"/dev/null")
      new_resource.updated_by_last_action(true)
    end
    home = ::File.expand_path "~#{new_resource.admin_user}"
    pubkey = ::File.read("#{home}/.ssh/id_rsa.pub").strip
    if pubkey != node["dsh"]["admin_groups"][new_resource.name]["pubkey"]
      node["dsh"]["admin_groups"][new_resource.name] = {
        "user" => new_resource.admin_user,
        "pubkey" => pubkey
      }
      new_resource.updated_by_last_action(true)
    end
  end
end

action :leave do
  execute "revoke access" do
    command "rm /tmp/#{new_resource.user}"
  end
end
