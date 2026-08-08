from unittest.mock import patch

from app.lambda_app import main as app

import json

def test_404():
    response = app({"httpMethod": "GET", "rawPath": "/nonexistent"}, {})
    assert response["statusCode"] == 404, "Expected status code 404 for nonexistent endpoint"

def test_root_path_works():
    response = app({"httpMethod": "GET", "rawPath": "/"}, {})
    assert response["statusCode"] == 200, "Expected status code 200 for the root path"

    body = json.loads(response["body"])
    assert body["message"] == "Hello, World!", "Expected a hello message for the root path"

def test_random_works():
    response = app({"httpMethod": "GET", "rawPath": "/random"}, {})
    assert response["statusCode"] == 200, "Expected status code 200 for /random endpoint"

    # Parse body as JSON
    body = json.loads(response["body"])
    assert "random_number" in body, "Response body should contain 'random_number'"
    random_number = body["random_number"]
    assert isinstance(random_number, int), "random_number should be an integer"
    assert 1 <= random_number <= 100, "random_number should be between 1 and 100"

def test_roll_dice_works():

    with patch('app.lambda_app.data.save_roll_history') as mock_save_roll_history:

        response = app({"httpMethod": "GET", "rawPath": "/roll/d20", "queryStringParameters": {"n": "5"}}, {})
        assert response["statusCode"] == 200, "Expected status code 200 for /roll/d20 endpoint"

        # Parse body as JSON
        body = json.loads(response["body"])
        assert "faces" in body, "Response body should contain 'faces'"
        assert body["faces"] == 20, "faces should be 20"
        assert "rolls" in body, "Response body should contain 'rolls'"
        rolls = body["rolls"]
        assert len(rolls) == 5, "There should be 5 rolls"
        
        mock_save_roll_history.assert_called_once()
        source_arg = mock_save_roll_history.call_args[0][1]
        assert source_arg == "lambda_app", "The lambda app should store the roll history with source 'lambda_app'"