load("@ytt:data", "data")
load("@ytt:json", "json")
load("@ytt:sha256", "sha256")
load("@ytt:struct", "struct")

# ###########
# OPERATOR
# ###########

# The names of the operator resources in the upstream manifest.
deployment = "cnpg-controller-manager"
config_name = "cnpg-controller-manager-config"
image_pull_secret_name = "canonical-registry-credentials"

# The labels selecting the operator Pods, as in the upstream Deployment.
selector = {"app.kubernetes.io/name": "cloudnative-pg"}

# ###########
# CONFIGURATION
# ###########

def _join(values):
  return ",".join(values)
end

# The operator configuration computed from the package values. `config` is merged on top of it.
# The operator reads it from the `cnpg-controller-manager-config` ConfigMap, as strings.
# See: https://cloudnative-pg.io/docs/1.30/operator_conf
def operator_config():
  values = data.values
  config = {
    # The operator copies this Secret to the namespace of each Cluster, as `<cluster>-pull`,
    # so that the instances can pull the operator image they bootstrap with.
    "PULL_SECRET_NAME": image_pull_secret_name,
    "CLUSTERS_ROLLOUT_DELAY": values.upgrades.clusters_rollout_delay,
    "INSTANCES_ROLLOUT_DELAY": values.upgrades.instances_rollout_delay,
    "ENABLE_INSTANCE_MANAGER_INPLACE_UPDATES": values.upgrades.in_place_updates,
  }
  if values.inherited_annotations:
    config["INHERITED_ANNOTATIONS"] = _join(values.inherited_annotations)
  end
  if values.inherited_labels:
    config["INHERITED_LABELS"] = _join(values.inherited_labels)
  end

  for name, value in struct.decode(values.config).items():
    config[name] = value
  end
  return {name: _format(value) for name, value in config.items() if value != None}
end

# The checksum of the operator configuration, which the operator only reads at startup.
# It's added to the Pod template, so that a change rolls out the operator.
def operator_config_checksum():
  return sha256.sum(json.encode(operator_config()))
end

# ###########
# FLAGS
# ###########

# The flags computed from the package values. `args` is merged on top of them.
def operator_args():
  args = {"log-level": data.values.observability.logging.level}
  for name, value in struct.decode(data.values.args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# Merges the given flags into the upstream ones, keeping their order. New flags are appended,
# and flags set to null are removed. The upstream `controller` subcommand, and the flags without a value,
# like `--leader-elect`, are kept as they are.
def _merge_args(upstream, overrides):
  commands = [arg for arg in upstream if not arg.startswith("-")]
  flags = {}
  for arg in upstream:
    if arg.startswith("-"):
      name, separator, value = arg.lstrip("-").partition("=")
      flags[name] = value if separator else None
    end
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return commands + ["--" + name if value == None else "--" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlay replacing the upstream container args.
def args_merger(overrides):
  return lambda left, _: _merge_args(left, overrides)
end
