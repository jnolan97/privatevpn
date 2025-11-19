import yaml
from cerberus import Validator

# Define the schema for the YAML configuration
schema = {
    'name': {'type': 'string', 'required': True},
    'version': {'type': 'string', 'required': True},
    'servers': {'type': 'list', 'schema': {'type': 'dict', 'schema': {
        'address': {'type': 'string', 'required': True},
        'port': {'type': 'integer', 'min': 1, 'max': 65535, 'required': True},
        'protocol': {'type': 'string', 'allowed': ['tcp', 'udp'], 'required': True}
    }}},
}

# Function to validate the YAML configuration
def validate_yaml_config(yaml_content):
    validator = Validator(schema)
    if not validator.validate(yaml_content):
        raise ValueError(f"Invalid configuration: {validator.errors}")

# Load the YAML configuration
with open('config.yaml', 'r') as file:
    try:
        yaml_content = yaml.safe_load(file)
        validate_yaml_config(yaml_content)
        # Proceed with creating or updating the profile
    except ValueError as e:
        print(e)
    except Exception as ex:
        print(f'An error occurred: {ex}')