resource "rancher2_cloud_credential" "dcentralab-dub" {
  name = "dcentralab-dub"

  amazonec2_credential_config {
    access_key = var.access_key_dcentralab-dub
    secret_key = var.secret_key_dcentralab-dub
  }
}

resource "rancher2_cloud_credential" "chainport" {
  name = "chainport"

  amazonec2_credential_config {
    access_key = var.access_key_chainport
    secret_key = var.secret_key_chainport
  }
}

resource "rancher2_cluster" "import_cluster_dcentralab-dub" {
  for_each = var.importing_clusters_dcentralab-dub

  name = each.value.cluster_name

  eks_config_v2 {
    cloud_credential_id = rancher2_cloud_credential.dcentralab-dub
    name                = each.value.cluster_name
    region              = var.region
    imported            = true
  }
}

resource "rancher2_cluster" "import_cluster_chainport" {
  for_each = var.importing_clusters_chainport

  name = each.value.cluster_name

  eks_config_v2 {
    cloud_credential_id = rancher2_cloud_credential.chainport
    name                = each.value.cluster_name
    region              = var.region
    imported            = true
  }
}