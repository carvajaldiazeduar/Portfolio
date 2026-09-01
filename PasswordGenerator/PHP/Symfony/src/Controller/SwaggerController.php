<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class SwaggerController extends AbstractController
{
    #[Route('/openapi.json', name: 'openapi_json')]
    public function openapi(): Response
    {
        return new Response(file_get_contents($this->getParameter('kernel.project_dir') . '/public/openapi.json'), 200, ['Content-Type' => 'application/json']);
    }

    #[Route('/swagger', name: 'swagger')]
    public function swagger(): Response
    {
        return new Response(file_get_contents($this->getParameter('kernel.project_dir') . '/public/swagger.html'), 200, ['Content-Type' => 'text/html']);
    }
}
