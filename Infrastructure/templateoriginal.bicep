param connections_aci_1_name string = 'aci-1'
param workflows_tklogicapptodelete_name string = 'tklogicapptodelete'
param acr_name string = 'tkwuscr'
param containerGroups_encodeURIComponent_variables_ci_name_externalid string = '/subscriptions/@{encodeURIComponent(\'708854ac-164b-4d34-a0b9-69ff53d7704d\')}/resourceGroups/@{encodeURIComponent(\'tkcr-rg\')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent(variables(\'ci_name\'))}'
param containerGroups_encodeURIComponent_body_Create_or_update_a_container_group_name_externalid string = '/subscriptions/@{encodeURIComponent(\'708854ac-164b-4d34-a0b9-69ff53d7704d\')}/resourceGroups/@{encodeURIComponent(\'tkcr-rg\')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent(body(\'Create_or_update_a_container_group\')?[\'name\'])}'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acr_name
  location: 'westus'
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
      azureADAuthenticationAsArmPolicy: {
        status: 'enabled'
      }
      softDeletePolicy: {
        retentionDays: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

resource connections_aci_1_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_aci_1_name
  location: 'centralus'
  kind: 'V1'
  properties: {
    displayName: 'Ruchira_Kumarasinghe@bradycorp.com'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {
    }
    nonSecretParameterValues: {
      'token:TenantId': 'a871fdca-22af-4ddd-b902-f381041deaa3'
      'token:grantType': 'code'
    }
    createdTime: '2023-01-03T03:46:36.3137984Z'
    changedTime: '2023-01-08T01:38:49.6004525Z'
    api: {
      name: 'aci'
      displayName: 'Azure Container Instance'
      description: 'Easily run containers on Azure with a single command. Create container groups, get the logs of a container and more.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1479/1.0.1479.2452/aci/icon.png'
      brandColor: '#0089D0'
      id: '/subscriptions/708854ac-164b-4d34-a0b9-69ff53d7704d/providers/Microsoft.Web/locations/centralus/managedApis/aci'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

resource registries_tkwuscr_name_repositories_admin 'Microsoft.ContainerRegistry/registries/scopeMaps@2022-02-01-preview' = {
  parent: acr
  name: '_repositories_admin'
  properties: {
    description: 'Can perform all read, write and delete operations on the registry'
    actions: [
      'repositories/*/metadata/read'
      'repositories/*/metadata/write'
      'repositories/*/content/read'
      'repositories/*/content/write'
      'repositories/*/content/delete'
    ]
  }
}

resource registries_tkwuscr_name_repositories_pull 'Microsoft.ContainerRegistry/registries/scopeMaps@2022-02-01-preview' = {
  parent: acr
  name: '_repositories_pull'
  properties: {
    description: 'Can pull any repository of the registry'
    actions: [
      'repositories/*/content/read'
    ]
  }
}

resource registries_tkwuscr_name_repositories_push 'Microsoft.ContainerRegistry/registries/scopeMaps@2022-02-01-preview' = {
  parent: acr
  name: '_repositories_push'
  properties: {
    description: 'Can push to any repository of the registry'
    actions: [
      'repositories/*/content/read'
      'repositories/*/content/write'
    ]
  }
}

resource workflows_tklogicapptodelete_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_tklogicapptodelete_name
  location: 'centralus'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
            }
          }
        }
      }
      actions: {
        Create_or_update_a_container_group: {
          runAfter: {
            'acr-pw': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              location: 'west us'
              properties: {
                containers: [
                  {
                    name: '@variables(\'ci_name\')'
                    properties: {
                      environmentVariables: [
                        {
                          name: 'max_count'
                          value: '@{variables(\'loopCount\')}'
                        }
                      ]
                      image: '@variables(\'image\')'
                      resources: {
                        requests: {
                          cpu: 1
                          memoryInGB: '3.5'
                        }
                      }
                    }
                  }
                ]
                imageRegistryCredentials: [
                  {
                    password: 'WbpzAGPQvRaYFmFcjdpj9gWYRRiMXagjRCzVCY+4v4+ACRCu7vLu'
                    server: 'tkwuscr.azurecr.io'
                    username: 'tkwuscr'
                  }
                ]
                osType: 'Linux'
                restartPolicy: 'OnFailure'
                sku: 'Standard'
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'aci\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: containerGroups_encodeURIComponent_variables_ci_name_externalid
            queries: {
              'x-ms-api-version': '2019-12-01'
            }
          }
        }
        Until: {
          actions: {
            Condition: {
              actions: {
                Delete_a_container_group: {
                  runAfter: {
                    Get_logs_from_a_container_instance: [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'aci\'][\'connectionId\']'
                      }
                    }
                    method: 'delete'
                    path: containerGroups_encodeURIComponent_variables_ci_name_externalid
                    queries: {
                      'x-ms-api-version': '2019-12-01'
                    }
                  }
                }
                Get_logs_from_a_container_instance: {
                  runAfter: {
                  }
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'aci\'][\'connectionId\']'
                      }
                    }
                    method: 'get'
                    path: '${containerGroups_encodeURIComponent_variables_ci_name_externalid}/containers/@{encodeURIComponent(variables(\'ci_name\'))}/logs'
                    queries: {
                      'x-ms-api-version': '2019-12-01'
                    }
                  }
                }
              }
              runAfter: {
                Get_properties_of_a_container_group: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {
                  Delay: {
                    runAfter: {
                    }
                    type: 'Wait'
                    inputs: {
                      interval: {
                        count: 10
                        unit: 'Second'
                      }
                    }
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@body(\'Get_properties_of_a_container_group\')?[\'properties\']?[\'instanceView\']?[\'state\']'
                      'Succeeded'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Get_properties_of_a_container_group: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'aci\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: containerGroups_encodeURIComponent_body_Create_or_update_a_container_group_name_externalid
                queries: {
                  'x-ms-api-version': '2019-12-01'
                }
              }
            }
          }
          runAfter: {
            Create_or_update_a_container_group: [
              'Succeeded'
            ]
          }
          expression: '@equals(body(\'Get_properties_of_a_container_group\')?[\'properties\']?[\'instanceView\']?[\'state\'], \'Succeeded\')'
          limit: {
            count: 60
            timeout: 'PT1H'
          }
          type: 'Until'
        }
        'acr-pw': {
          runAfter: {
            'acr-un': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'acr-pw'
                type: 'string'
                value: 'WbpzAGPQvRaYFmFcjdpj9gWYRRiMXagjRCzVCY+4v4+ACRCu7vLu'
              }
            ]
          }
        }
        'acr-server-name': {
          runAfter: {
            'image-name': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'acr-server-name'
                type: 'string'
                value: 'tkwuscr.azurecr.io'
              }
            ]
          }
        }
        'acr-un': {
          runAfter: {
            'acr-server-name': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'acr-un'
                type: 'string'
                value: 'tkwuscr'
              }
            ]
          }
        }
        'ci-name': {
          runAfter: {
            loopCount: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ci_name'
                type: 'string'
                value: 'test1-ci'
              }
            ]
          }
        }
        'image-name': {
          runAfter: {
            'ci-name': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'image'
                type: 'string'
                value: 'tkwuscr.azurecr.io/helloconsole:latest'
              }
            ]
          }
        }
        loopCount: {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'loopCount'
                type: 'integer'
                value: 5
              }
            ]
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          aci: {
            connectionId: connections_aci_1_name_resource.id
            connectionName: 'aci-1'
            id: '/subscriptions/708854ac-164b-4d34-a0b9-69ff53d7704d/providers/Microsoft.Web/locations/centralus/managedApis/aci'
          }
        }
      }
    }
  }
}
