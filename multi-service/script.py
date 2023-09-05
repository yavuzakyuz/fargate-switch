import hcl
import sys

def write_back_hcl(tf_data):
    with open('locals.tf', 'w') as f:
        f.write("locals {\n")
        f.write("  ecs_services = {\n")

        for developer, settings in tf_data["locals"]["ecs_services"].items():
            f.write(f"    {developer} = {{\n")
            for key, value in settings.items():
                if isinstance(value, str) and value.startswith("${"):
                    f.write(f'      {key} = {value}\n')
                elif isinstance(value, int):
                    f.write(f'      {key} = {value}\n')
                else:
                    f.write(f'      {key} = "{value}"\n')
            f.write("    },\n")
        f.write("  }\n")
        f.write("}\n")

def modify_tf_file(developer_name, image_tag):
    # Load existing locals.tf file
    with open('locals.tf', 'r') as f:
        tf_data = hcl.load(f)

    if "locals" in tf_data and "ecs_services" in tf_data["locals"]:
        if developer_name in tf_data["locals"]["ecs_services"]:
            print(f"Updating image tag for {developer_name} to {image_tag}")
            tf_data["locals"]["ecs_services"][developer_name]["image_tag"] = image_tag
        else:
            print(f"Creating new developer {developer_name} with image tag {image_tag}")
            tf_data["locals"]["ecs_services"][developer_name] = {
                "container_name": "ecsdemo",
                "container_port": 80,
                "image_tag": image_tag,
                "domain": f"{developer_name}.{'${local.domain}'}"
            }
        write_back_hcl(tf_data)

if __name__ == "__main__":
    args = sys.argv[1:]
    arg_dict = {}
    for arg in args:
        key, value = arg.split("=")
        arg_dict[key] = value

    developer_name = arg_dict.get("developername")
    image_tag = arg_dict.get("imagetag")

    if developer_name and image_tag:
        modify_tf_file(developer_name, image_tag)
    else:
        print("Both developername and imagetag must be provided.")
